class ApplicationController < ActionController::Base
  def god
    @god ||= God.instance
  end
end
