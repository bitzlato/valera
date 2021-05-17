# frozen_string_literal: true

class UpstreamsController < ApplicationController
  def index
    upstreams = Upstream.all
    render locals: { upstreams: upstreams }
  end
end
