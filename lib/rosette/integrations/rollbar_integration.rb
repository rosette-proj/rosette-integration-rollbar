# encoding: UTF-8

require 'rosette/integrations'
require 'grape-rollbar'

module Rosette
  module Integrations
    class RollbarIntegration < Integration
      autoload :Configurator,   'rosette/integrations/rollbar/configurator'

      def integrate(obj)
        if integrates_with?(obj)
          integrate_with_grape(obj) if obj.is_a?(Class)
        end
      end

      def self.configure
        config = Configurator.new
        yield config if block_given?
        new(config)
      end

      def integrates_with?(obj)
        obj.ancestors.include?(Grape::API)
      end

      def integrate_with_grape(obj)
        obj.send(:include, GrapeRollbar)
        obj.track_errors_with_rollbar(configuration.rollbar_notifier)
      end

      def error(exception, **options)
        configuration.rollbar_notifier.error(exception, options)
      end

    end
  end
end
