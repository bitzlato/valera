require 'open-uri'
class KassaRates
  URL = 'https://kassa.cc/valuta.xml'
  EXPIRES_IN = 10.seconds

  # Подготовленные курсы
  # @return
  # => {:pmusdtcsbrub=>67.57631955,
  #:pmusdqwrub=>63.224955,
  #:pmusdmcr=>67.1672169,
  #:pmusdbtc=>1.6112782134264622e-05,
  #:pmusdacrub=>67.57631955,
  #:pmvusdtcsbrub=>67.57631955,
  #:pmvusdqwrub=>63.224955,
  #:pmvusdmcr=>67.3159815,
  #:pmvusdbtc=>1.609443044618459e-05,
  #:pmvusdacrub=>67.57631955,
  #:tcsbrubpmusd=>0.012927847983026196,
  #:tcsbrubpmvusd=>0.012821094490185352,
  #:tcsbrubbtc=>2.1618228164882926e-07,
  #:qwrubpmusd=>0.011342558614339663,
  #:qwrubpmvusd=>0.011342558614339663,
  #:qwrubbtc=>2.1753418903833302e-07,
  #:btcpmusd=>51752.133499999996,
  #:btcpmvusd=>51749.9544628,
  #:btctcsbrub=>3780470.154962108,
  #:btcqwrub=>3893131.8260674877,
  #:btcmcr=>3652353.0921527413,
  #:btcacrub=>3780470.154962108,
  #:acrubpmusd=>0.012927847983026196,
  #:acrubpmvusd=>0.012843779607414032,
  def rates
    Rails.cache.fetch self.class.name + '_rates', :expires_in => EXPIRES_IN do
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
    Rails.cache.fetch self.class.name + '_raw_data', :expires_in => EXPIRES_IN do
      URI.open(URL).read
    end
  end
end
