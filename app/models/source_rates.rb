require 'open-uri'
# Отдаёт текущий базовый курс с внешней биржи
class SourceRates
  EXPIRES_IN = 10.seconds
  URL = 'https://price.monolithos.pro/v1/setzer/price/list'

  # Подготовленные курсы
  def rates
    raw_data
      .each_with_object({}) { |i,a| a[(i['first_currency']+i['second_currency']).downcase.to_sym]=i['price'].to_d }
  end

  private

  def raw_data
    Rails.cache.fetch :source_rates, :expires_in => EXPIRES_IN do
      JSON.parse(URI.open(URL).read)['result']
    end
  end
end
