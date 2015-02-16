# encoding: UTF-8

module Rosette
  module Integrations
    class RollbarIntegration < Integration

      class JavaException < StandardError
        attr_reader :exception

        def initialize(exception)
          @exception = exception
        end

        def method_missing(method, *args, &block)
          exception.send(method, *args, &block)
        end

        def respond_to_missing?(method, include_private = false)
          exception.respond_to?(method, include_private)
        end
      end

    end
  end
end
