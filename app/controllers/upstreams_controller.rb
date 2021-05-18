# frozen_string_literal: true

class UpstreamsController < ApplicationController
  def index
    upstreams = Upstream.all
    render locals: { upstreams: upstreams }
  end

  def show
    redirect_to upstreams_path
  end
end
