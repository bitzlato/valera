require 'open-uri'
class KassaRates
  URL = 'https://kassa.cc/valuta.xml'
  EXPIRES_IN = 10.seconds

  # Подготовленные курсы
  def rates
    Rails.cache.fetch self.class.name + '_rates', expires_in: EXPIRES_IN do
      Nokogiri::XML.parse(raw_data)
        .xpath('//item')
        .each_with_object({}) { |e, h| h[market(e)]=e.xpath('out').text.to_f/e.xpath('in').text.to_f }
    end
  end

  private

  def market(e)
    (e.xpath('from').text + e.xpath('to').text)
      .downcase
      .gsub('erc','')
      .gsub('trc','')
      .gsub('cardrub','mcr')
      # .gsub('rub','mcr')
      .to_sym
  end

  def raw_data
    Rails.cache.fetch self.class.name + '_raw_data', expires_in: EXPIRES_IN do
      URI.open(URL).read
    end
  end
end
