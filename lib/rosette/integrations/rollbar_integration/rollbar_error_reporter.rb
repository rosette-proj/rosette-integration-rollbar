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
          rollbar_notifier.error(
            wrap_java_exception(error), options
          )
        end

        def report_warning(error, options = {})
          rollbar_notifier.warn(
            wrap_java_exception(error), options
          )
        end

        private

        def wrap_java_exception(error)
          if error.is_a?(Java::JavaLang::Exception)
            JavaException.new(error)
          else
            error
          end
        end
      end

    end
  end
end
