class UniversesController < ApplicationController
  def index
    render locals: { universes: god.universes }
  end

  def show
    universe = god.universes.find { |u| u.id == params[:id] }
    render locals: { universe: universe }
  end
end
