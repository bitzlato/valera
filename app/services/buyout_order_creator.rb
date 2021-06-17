class BuyoutOrderCreator
  include AutoLogger

  self.class.delegate :call, to: :new

  def call(trade, buyout_account)
    buyout_order = trade.with_lock do
      raise "Trade #{trade.id} already buyouted" if trade.buyout_order.present?

      binding.pry
      case trade.side.to_s
      when 'bid'
        price = trace.price
        side = 'ask'
      when 'ask'
        side = 'bid'
      else
        raise "Wrong trade side #{trade.side}"
      end

      price = trade.price + 10
      side = trade.side.to_s == 'bid' ? 'ask' : 'bid'
      # TODO Пjcxbnfnm
      #
      # price
      BuyoutOrder.create!(
        original_trade: trade,
        trade_account_id: trade.account.id,
        market_id: trade.market_id,
        volume: trade.amount,
        side: side,
        price: price,
        buyout_account_id: buyout_account.id
      )
    end
    post_buyout_order(buyout_order, buyout_account)
    buyout_order
  end

  def post_buyout_order(buyout_order, account)
    logger.info "Post buyout_order #{buyout_order.as_json}"
    return if ENV.false? 'DISABLE_BUYOUT_POST'
    buyout_order.with_lock do
      order = account.client.create_order(
        market:   market.binance_symbol,
        ord_type: :limit,
        price:    buyout_order.price,
        volume:   buyout_order.volume,
        side:     buyout_order.side
      )

      buyout_order.update! target_order_id: order['id'], status: :posted
    end
  end
end
