# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

# frozen_string_literal: true

class DrainersController < ApplicationController
  def index
    drainers = Drainer.all
    render locals: { drainers: drainers }
  end

  def show
    redirect_to drainers_path
  end
end
