require 'faraday'

module Faraday
  class Adapter
    class NetHttp < Faraday::Adapter
      # See original definition here:
      # https://github.com/technoweenie/faraday/blob/412844ac1d90faef1bba5eed25091279358bdf99/lib/faraday/adapter/net_http.rb#L107
      def ssl_verify_mode(_ssl)
        OpenSSL::SSL::VERIFY_NONE
      end
    end
  end
end if ENV.true? 'DISABLE_SSL_VERIFICATION'
