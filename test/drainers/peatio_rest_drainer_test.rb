# frozen_string_literal: true

class PeatioRestDrainerTest < ActiveSupport::TestCase
  setup do
    @drainer = PeatioRestDrainer.new Market.all.first
  end

  test 'update_market_depth!' do
    data = {
      'timestamp' => 1_621_231_184,
      'asks' => [['44364.8968', '0.001'], ['44452.3497', '0.001'], ['44548.548', '0.001'], ['44670.9822', '0.001'],
                 ['44959.577', '0.001']],
      'bids' => [['42965.6491', '0.001'], ['42904.432', '0.001'], ['42747.0166', '0.001'], ['42633.3278', '0.001'],
                 ['42423.4406', '0.001']]
    }

    @drainer.send :update_market_depth!, data
  end
end
