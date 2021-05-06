class UniverseSettingsController < ApplicationController
  def index
    render locals: { universes: god.universes }
  end

  def update
  end

  def show
    universe = Universe.find params[:id]
    render locals: { universe: universe }
  end
end
