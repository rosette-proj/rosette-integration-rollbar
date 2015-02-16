# encoding: UTF-8

module Rosette
  module Integrations
    class RollbarIntegration < Integration

      class JavaException < StandardError
        attr_reader :exception

        def initialize(exception)
          @exception = exception
        end

        def backtrace
          exception.backtrace
        end

        def message
          "<#{exception.class}> #{exception.message}"
        end
      end

    end
  end
end
