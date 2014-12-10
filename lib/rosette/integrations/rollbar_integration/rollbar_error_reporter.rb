# encoding: UTF-8

module Rosette
  module Integrations
    class RollbarIntegration < Integration

      class RollbarErrorReporter
        attr_reader :rollbar_notifier

        def initialize(rollbar_notifier)
          @rollbar_notifier = rollbar_notifier
        end

        def report_error(error, options = {})
          rollbar_notifier.error(error, options)
        end

        def report_warning(error, options = {})
          rollbar_notifier.warn(error, options)
        end
      end

    end
  end
end
