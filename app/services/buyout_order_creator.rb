# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

# frozen_string_literal: true

class BuyoutOrderCreator
  include AutoLogger

  ASK_PERCENTAGE = 0.1
  BID_PERCENTAGE = 0.1

  self.class.delegate :call, to: :new

  def call(trade:, buyout_account:, ask_percentage: ASK_PERCENTAGE, bid_percentage: BID_PERCENTAGE)
    buyout_order = nil
    trade.with_lock do
      if trade.buyout_order.present?
        logger.warn "Trade #{trade.id} already buyouted with order #{trade.buyout_order.id}. Skip"
        logger.warn caller.join("\n")
        return nil
      end

      upstream_market = UpstreamMarket.find_by!(account: buyout_account, market: trade.market)
      side, price, ignore_message = calculate_price(upstream_market, trade, ask_percentage, bid_percentage)

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
          askPrice: upstream_market.askPrice,
          bidPrice: upstream_market.bidPrice
        }
      )
    end
    if buyout_order.initial?
      post_buyout_order(buyout_order)
    else
      logger.warn("Wrong state of buyout #{buyout_order.id} - #{buyout_order.status}. Skip posting")
    end
    buyout_order
  end

  private

  def calculate_price(upstream_market, trade, ask_percentage, bid_percentage)
    # Sold expensive, buy cheaper
    if trade.side? :ask
      side = :bid
      raise "No bidPrice in #{upstream_market}" if upstream_market.bidPrice.to_d.zero?

      price = (100 + bid_percentage).percent_of(upstream_market.bidPrice)
      price = Currency.round(upstream_market.market.quote, price)
      if price >= trade.price
        ignore_message = "Target price (#{price}) is higher than traded (#{trade.price}) for trade #{trade.id}"
        logger.info ignore_message
      end
    else # Bought cheap, sell expensive
      side = :ask
      raise "No bidPrice in #{upstream_market}" if upstream_market.askPrice.to_d.zero?

      price = (100 - ask_percentage).percent_of(upstream_market.askPrice)
      price = Currency.round(upstream_market.market.quote, price)
      if price <= trade.price
        ignore_message = "Target price (#{price}) is lower than traded (#{trade.price}) for trade #{trade.id}"
        logger.info ignore_message
      end
    end
    [side, price, ignore_message]
  end

  def post_buyout_order(buyout_order)
    logger.info "Post buyout_order #{buyout_order.as_json}"
    if ENV.true? 'DISABLE_BUYOUT'
      logger.info 'Skip buyout posting as it disabled'
      return
    end

    buyout_order.with_lock do
      raise "buyout_order #{buyout_order.id} has wrong status #{buyout_order.status}" unless buyout_order.initial?

      order = buyout_order.buyout_account.client.create_order(
        time_in_force: 'IOC',
        market: buyout_order.market,
        ord_type: :limit,
        price: buyout_order.price,
        volume: buyout_order.volume,
        side: buyout_order.side
      )

      logger.info("Posting response: #{order}")

      status = order['status'] == 'FILLED' ? :done : :posted
      buyout_order.update! target_order_id: order['id'], status: status,
                           meta: buyout_order.meta.merge(response: order)
    rescue StandardError => e
      report_exception e
      buyout_order.update! status: :errored, ignore_message: e.message
    end
  end
end
