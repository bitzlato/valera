# frozen_string_literal: true

class BuyoutOrderCreator
  include AutoLogger

  ASK_PERCENTAGE = 0.1 # % На сколько процентов от текущец цены на целевой бирже готовые дороже купить
  BID_PERCENTAGE = 0.1 # % На сколько процентов он текущей цены на целевой бирже готовые дешевле продать

  self.class.delegate :call, to: :new

  def call(trade:, buyout_account:, ask_percentage: ASK_PERCENTAGE, bid_percentage: BID_PERCENTAGE)
    buyout_order = nil
    trade.with_lock do
      raise "Trade #{trade.id} already buyouted" if trade.buyout_order.present?

      um = UpstreamMarket.find_by!(account: buyout_account, market: trade.market)

      # Sold expensive, buy cheaper
      if trade.side? :bid
        side = 'ask'
        price = (100 + ask_percentage).percent_of(um.bidPrice)
        if price >= trade.price
          ignore_message = "Target price (#{price}) is larger than original (#{trade.price}) for trade #{trade.id}. Skip buyout.."
          logger.info ignore_message
        end
      else # Bought cheap, sell expensive
        side = 'bid'
        price = (100 - bid_percentage).percent_of(um.askPrice)

        if price <= trade.price
          ignore_message = "Target price (#{price}) is lower than original (#{trade.price}) for trade #{trade.id}. Skip buyout.."
          logger.info ignore_message
        end
      end

      buyout_order = BuyoutOrder.create!(
        status: ignore_message.nil? ? :initial : :ignored,
        original_trade: trade,
        trade_account_id: trade.account.id,
        market_id: trade.market_id,
        volume: trade.amount,
        side: side,
        price: price,
        ignore_message: ignore_message,
        buyout_account_id: buyout_account.id,
        meta: {
          askPercentage: ask_percentage,
          bidPercentage: bid_percentage,
          askPrice: um.askPrice,
          bidPrice: um.bidPrice
        }
      )
    end
    post_buyout_order(buyout_order, buyout_account) if buyout_order.initial?
    buyout_order
  end

  private

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
