# frozen_string_literal: true

# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

require_relative 'base_client'

module Valera
  class MonolithosClient < BaseClient
    URL = 'https://price.monolithos.pro/v1/setzer/price/list'
    # [{"first_currency"=>"ETH", "second_currency"=>"RUB", "price"=>"226330.4259100000", "date"=>1632213940.111},
    # {"first_currency"=>"ETH", "second_currency"=>"USD", "price"=>"3085.7596841298", "date"=>1632213944.215},
    # {"first_currency"=>"ETH", "second_currency"=>"MDT", "price"=>"1697.3498621156", "date"=>1632213944.273},
    # {"first_currency"=>"MDT", "second_currency"=>"MCR", "price"=>"133.3434143200", "date"=>1632213944.378},
    # {"first_currency"=>"USD", "second_currency"=>"MDT", "price"=>"0.5500589922", "date"=>1632213944.491},
    # {"first_currency"=>"USD", "second_currency"=>"RUB", "price"=>"73.3315000000", "date"=>1632213944.562},
    # {"first_currency"=>"BTC", "second_currency"=>"MDT", "price"=>"23875.9027171788", "date"=>1632213874.489},
    # {"first_currency"=>"BTC", "second_currency"=>"RUB", "price"=>"3179876.7677600000", "date"=>1632213876.008},
    # {"first_currency"=>"MDT", "second_currency"=>"UAH", "price"=>"47.5744160173", "date"=>1632213876.534},
    # {"first_currency"=>"MDT", "second_currency"=>"USD", "price"=>"1.8172406254", "date"=>1632213876.632},
    # {"first_currency"=>"UAH", "second_currency"=>"RUB", "price"=>"2.8016964285", "date"=>1632213876.921},
    # {"first_currency"=>"BTC", "second_currency"=>"USD", "price"=>"43375.0000000000", "date"=>1632213876.955},
    # {"first_currency"=>"USD", "second_currency"=>"UAH", "price"=>"26.5762061902", "date"=>1632213877.315}],
    def fetch
      JSON.parse(URI.parse(URL).open.read).fetch('result')
    end
  end
end
