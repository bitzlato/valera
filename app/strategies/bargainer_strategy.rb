# frozen_string_literal: true

class BargainerStrategy < Strategy
  # Настройки стратегии проторговщика
  #
  class Settings < StrategySettings
    attribute :base_volume, BigDecimal, default: 0.0001
    attribute :base_threshold, BigDecimal, default: 0.01
    attribute :base_max_upstream_threshold, BigDecimal, default: 0.2
    attribute :base_max_day_trading_amount, BigDecimal, default: 1

    validates :base_volume, presence: true,
                            numericality: { greater_than: 0 }
    validates :base_threshold, presence: true,
                               numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }
    validates :base_max_upstream_threshold, presence: true,
                                            numericality: { greater_than: 0, less_than_or_equal_to: 1 }
    validates :base_max_day_trading_amount, presence: true,
                                            numericality: { greater_than: 0 }
  end

  def self.description
    %{
    <p>Проторговщик. Цель - создать цену.</p>
    <p>Делает заявки на объём <code>base_volume</code> базовой валюты по средней цене в стаканe, с разбросом от 0 до <code>base_threshold</code> %.</p>
    <p>Если на целевой бирже (peatio) стакана нет, то используется средняя цена из стакана биржи-источника (binance).</p>
    <p>Если средняя цена стакана целевой биржи смещена более чем на <code>base_max_upstream_threshold</code> % от биржи-источника, то используется цена максимального смещения.</p>
    <p>Так как заявки на продажу и покупку по примерно одинаковой цене (цена покупки и продажи будет идентичной если <code>base_threshold=0</code>), то с большой вероятностью он покупает сам у себя.</p>
    <p class="alert alert-warning">Пока в peatio не сформирован стакан цена берется из стакана binance</p>
    }.html_safe
  end

  private

  def calculate_price(side)
    return nil if upstream_markets.find_by_upstream!(:binance).avgPrice.nil?

    threshold = settings.base_threshold
    threshold = threshold * rand(100) / 100
    threshold = -threshold if side == :bid
    logger.debug "#{side} threshold = #{threshold}"
    binance_average_price = upstream_markets.find_by_upstream!(:binance).avgPrice
    peatio_upstream = upstream_markets.find_by_upstream!(:peatio)
    peatio_average_price = (peatio_upstream.high + peatio_upstream.low) / 2

    upstream_threshold = (binance_average_price - peatio_average_price).abs / (binance_average_price / 100.0)
    logger.info "Upstream threshold #{upstream_threshold}"
    if upstream_threshold > settings.base_max_upstream_threshold
      logger.warn "Upstream threshold is too much #{upstream_threshold} > #{settings.base_max_upstream_threshold} (binance:#{binance_average_price} ; peatio:#{peatio_average_price})"
      average_price = binance_average_price
    else
      average_price = peatio_average_price
    end

    average_price + average_price * threshold / 100
    # TODO: Брать среднюю цену стакана из peatio
  end

  def calculate_volume(_side)
    day_trading_value = account.day_trades_amounts[market.id]
    return if day_trading_value.nil?

    if day_trading_value >= settings.base_max_day_trading_amount
      logger.debug "Skip ordering. Met day trading limit #{day_trading_value} >= #{settings.base_max_day_trading_amount}"
      nil
    else
      settings.base_volume
    end
  end
end
