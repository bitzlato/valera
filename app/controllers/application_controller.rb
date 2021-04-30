class ApplicationController < ActionController::Base

  def god
    @god ||= God.new
  end
end
