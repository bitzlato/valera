# frozen_string_literal: true

class BuyoutOrderCreator
  include AutoLogger

  ASK_PERCENTAGE = 0.1 # % На сколько процентов от текущец цены на целевой бирже готовые дороже купить
  BID_PERCENTAGE = 0.1 # % На сколько процентов он текущей цены на целевой бирже готовые дешевле продать

  self.class.delegate :call, to: :new

  def call(trade, buyout_account)
    trade.with_lock do
      raise "Trade #{trade.id} already buyouted" if trade.buyout_order.present?

      um = UpstreamMarket.all.find { |um| um.upstream.accounts.include?(buyout_account) && um.market == trade.market }

      # Продали дорого, нужно купить дешевле
      if trade.side? :bid
        side = 'ask'
        price = (100+ASK_PERCENTAGE).percent_of(um.bidPrice)
        if price >= trade.price
          logger.warn("Target price (#{price}) is larger than original (#{trade.price}) for trade #{trade.id}. Skip buyout..")
          return
        end
        # Проверять что  цена адекватная
      else # Купили дешево, нужно продать дороже
        side = 'bid'
        price = (100-BID_PERCENTAGE).percent_of(um.askPrice)

        if price <= trade.price
          logger.warn("Target price (#{price}) is lower than original (#{trade.price}) for trade #{trade.id}. Skip buyout..")
          return
        end
        # Проверять что  цена адекватная
      end

      BuyoutOrder.create!(
        original_trade: trade,
        trade_account_id: trade.account.id,
        market_id: trade.market_id,
        volume: trade.amount,
        side: side,
        price: price,
        buyout_account_id: buyout_account.id,
        meta: {
          askPrice: um.askPrice,
          bidPrice: um.bidPrice
        }
      )
    end
    # post_buyout_order(buyout_order, buyout_account)
  end

  def post_buyout_order(buyout_order, account)
    logger.info "Post buyout_order #{buyout_order.as_json}"
    return if ENV.false? 'DISABLE_BUYOUT_POST'

    buyout_order.with_lock do
      order = account.client.create_order(
        market: market.binance_symbol,
        ord_type: :limit,
        price: buyout_order.price,
        volume: buyout_order.volume,
        side: buyout_order.side
      )

      buyout_order.update! target_order_id: order['id'], status: :posted
    end
  end
end
