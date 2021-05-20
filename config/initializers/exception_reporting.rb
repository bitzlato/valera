# frozen_string_literal: true

$debug_on_exception = Rails.env.development?

def catch_and_report_exception(options = {})
  yield
  nil
rescue options.fetch(:class) { StandardError } => e
  report_exception(e)
  e
end

def report_exception(exception, report_to_ets = true)
  report_exception_to_screen(exception)
  binding.pry if $debug_on_exception
  report_exception_to_ets(exception) if report_to_ets
end

def report_exception_to_screen(exception)
  logger.unknown exception.inspect if respond_to?(:logger)
  Rails.logger.unknown exception.inspect
  Rails.logger.unknown exception.backtrace.join("\n") if exception.respond_to?(:backtrace)
end

def report_exception_to_ets(exception)
  Bugsnag.notify exception if defined? Bugsnag
rescue StandardError => e
  report_exception(e, false)
end
