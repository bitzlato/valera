# frozen_string_literal: true

require 'test_helper'

class UniverseStateTest < ActiveSupport::TestCase
  test 'build new settings' do
    assert UniverseState.new(id: 1)
  end
end
