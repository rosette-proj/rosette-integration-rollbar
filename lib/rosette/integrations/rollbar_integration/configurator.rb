# encoding: UTF-8

module Rosette
  module Integrations
    class RollbarIntegration < Integration

      class Configurator
        attr_reader :rollbar_notifier

        def set_rollbar_notifier(notifier)
          @rollbar_notifier = notifier
        end
      end

    end
  end
end
