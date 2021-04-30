# Бот маркет-мейкер
#
# Проверяет уже установленные ордера на указанном маркете.
# Двигает их в нужнуж сторону или создаёт новые если их нет.
#
class Botya
  include AutoLogger
  # Наценка от базового курса
  BUY_MULT = 0.98
  SALE_MULT = 1.025

  # Процент разницы цены между текущей заявкой, на который зарзрешается сотавить заявку и не создавать новую
  #
  UNTOUCH_PERCENT = 0.01

  PRECISION = 4 # Gets from peatio config. Specific for every currency

  # @bit_place_threshold How far away from the mid price do you want to place the first ask (Enter 0.01 to indicate 1%)?
  # @ ask_place_threshold How far away from the mid price do you want to place the first ask (Enter 0.01 to indicate 1%)?
  def initialize(client: , market:)
    @market = market
    @client = client || PeatioClient.new
  end

  # @param side Enum[:buy, :sell]
  def cancel_orders!(side = nil)
    if side.present?
      logger.info "Cancel orders for #{market} with side #{side}"
      client.cancel_orders market: market, side: side
    else
      logger.info "Cancel orders for #{market}"
      client.cancel_orders market: market
    end
  end

  # @param side Enum[:buy, :sell]
  # @param volume Float
  # @param price Float
  def create_order!(side, volume, price)
    price=price.round(PRECISION)
    logger.debug "Perform #{side} order for #{market}, #{volume} for #{price}"
    existen_order = nil
    orders_to_cancel = []
    client.orders(market: market, type: side, state: :wait).each do |order|
      if price_outdated?(order['price'].to_d, price)
        logger.debug "Mark for cancel order ##{order['id']} as outdated price #{order['price']} <> #{price}"
        orders_to_cancel << order
      elsif order['remaining_volume'].to_d != volume.to_d
        logger.debug "Mark for cancel order ##{order['id']} as outdated volume #{order['remaining_volume']} <> #{volume}"
        orders_to_cancel << order
      elsif existen_order.present?
        logger.debug "Mark for cancel order ##{order['id']} as duplicate"
        orders_to_cancel << order
      else
        existen_order = order
      end
    end
    if existen_order.present?
      logger.debug "Existen #{side} order for #{market}, #{volume} for #{price}, don't need to create"
    else
      begin
        logger.info "Create #{side} order for #{market}, #{volume} for #{price}"
        order = client
          .create_order(market: market, ord_type: :limit, side: side, volume: volume, price: price)
        logger.debug "Created order ##{order['id']}"
      rescue => err
        logger.error err
        logger.warn "Order doesn't created!"
      end
    end
    orders_to_cancel.each do |order|
      logger.info "Cancel order ##{order['id']}"
      client.cancel_order order['id']
    rescue => err
      logger.error err
      logger.warn "Order doesn't canceled!"
    end
    logger.debug "Successful performed"
  rescue => err
    logger.error err
    :error
  end

  private

  attr_reader :market, :client

  def price_outdated?(price1, price2)
    price1 != price2
  end
end
