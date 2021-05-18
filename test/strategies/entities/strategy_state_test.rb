# frozen_string_literal: true

require 'test_helper'

class StrategyStateTest < ActiveSupport::TestCase
  test 'build new settings' do
    assert StrategyState.new(id: 1)
  end
end
