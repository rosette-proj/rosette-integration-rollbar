# encoding: UTF-8

require 'rosette/integrations'
require 'rollbar'

module Rosette
  module Integrations
    class RollbarIntegration < Integration
      autoload :Configurator,   'rosette/integrations/rollbar_integration/configurator'

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
        obj.endpoints.each do |endpoint|
          original_block = endpoint.block
          endpoint.block = lambda do |*args, &block|
            begin
              original_block.call(endpoint)
            rescue => e
              env = args.first.env['api.endpoint']
              configuration.rollbar_notifier.error(e, env.params, env.headers)
              raise e
            end
          end
        end
      end

      def error(exception, **options)
        configuration.rollbar_notifier.error(exception, options)
      end

    end
  end
end
