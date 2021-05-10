# frozen_string_literal: true

class UniverseChannel < ApplicationCable::Channel
  def self.update(universe)
    broadcast_to universe, {
      state: universe.state.as_json,
      settings: universe.settings.as_json
    }
  end

  def subscribed
    universe = Universe.find params[:id].split(':').last
    stream_from broadcasting_for universe
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
