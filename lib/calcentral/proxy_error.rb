module Calcentral
  class ProxyError < Exception
    attr_accessor :wrapped_exception, :log_message, :response

    def initialize(log_message, *args)
      @log_message = log_message
      if args && args.length > 0
        @response = args[0]
        @wrapped_exception = args[1]
      else
        @wrapped_exception = nil
        @response = {
          :body => log_message,
          :status_code => 500
        }
      end
    end
  end
end
