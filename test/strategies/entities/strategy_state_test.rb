# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

# frozen_string_literal: true

require 'test_helper'

class StrategyStateTest < ActiveSupport::TestCase
  test 'build new settings' do
    assert StrategyState.new(id: 1)
  end
end
