# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

# frozen_string_literal: true

class StrategyChannel < ApplicationCable::Channel
  def self.update(strategy)
    broadcast_to strategy, {
      state: strategy.state.as_json,
      settings: strategy.settings.as_json
    }
  end

  def subscribed
    strategy = Strategy.find params[:id].split(':').last
    stream_from broadcasting_for strategy
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
