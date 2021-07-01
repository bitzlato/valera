# frozen_string_literal: true

# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

require 'faraday'

if ENV.true? 'DISABLE_SSL_VERIFICATION'
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
  end
end
