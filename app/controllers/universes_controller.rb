# frozen_string_literal: true

class UniversesController < ApplicationController
  def index
    universes = god.universes
    universes.each &:reload
    render locals: { universes: universes }
  end

  def show
    universe = Universe.find params[:id]
    render locals: { universe: universe }
  end
end
