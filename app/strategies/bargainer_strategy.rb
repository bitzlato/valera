# frozen_string_literal: true

class BargainerStrategy < Universe
  # Настройки стратегии проторговщика
  #
  class Settings < UniverseSettings
    attribute :base_volume, BigDecimal, default: 0.0001
    attribute :base_threshold, BigDecimal, default: 0.01
    attribute :base_max_upstream_threshold, BigDecimal, default: 0.2

    validates :base_volume, presence: true, numericality: { greater_than: 0 }
    validates :base_threshold, presence: true,
                               numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }
    validates :base_max_upstream_threshold, presence: true,
                                            numericality: { greater_than: 0, less_than_or_equal_to: 0.5 }
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
    return nil if upstream_states[:binance].avgPrice.nil?

    threshold = settings.base_threshold
    threshold = threshold * rand(100) / 100
    threshold = -threshold if side == :bid
    logger.debug "#{side} threshold = #{threshold}"
    upstream_states[:binance].avgPrice + upstream_states[:binance].avgPrice * threshold / 100
    # TODO: Брать среднюю цену стакана из peatio
  end

  def calculate_volume(_side)
    settings.base_volume
  end
end
