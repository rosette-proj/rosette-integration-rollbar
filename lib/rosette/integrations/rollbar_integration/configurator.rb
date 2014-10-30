# encoding: UTF-8

module Rosette
  module Integrations
    class RollbarIntegration < Integration

      class Configurator
        attr_reader :rollbar_notifier, :log_expected_errors
        alias :log_expected_errors? :log_expected_errors

        def set_rollbar_notifier(notifier)
          @rollbar_notifier = notifier
          @log_expected_errors = true
        end

        def should_log_expected_errors(bool)
          @log_expected_errors = bool
        end
      end

    end
  end
end
