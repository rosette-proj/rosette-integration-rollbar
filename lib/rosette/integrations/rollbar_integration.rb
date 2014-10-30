# encoding: UTF-8

require 'rosette/integrations'
require 'rollbar'

module Rosette
  module Integrations

    class RollbarIntegration < Integration
      autoload :Configurator, 'rosette/integrations/rollbar_integration/configurator'

      def integrate(obj)
        if integrates_with?(obj)
          integrate_with_grape(obj)
        else
          raise Errors::ImpossibleIntegrationError,
            "Cannot integrate #{self.class.name} with #{obj}"
        end
      end

      def self.configure
        config = Configurator.new
        yield config if block_given?
        new(config)
      end

      def integrates_with?(obj)
        obj.is_a?(Class) && obj.ancestors.include?(Grape::API)
      end

      def error(exception, **options)
        configuration.rollbar_notifier.error(exception, options)
      end

      private

      def integrate_with_grape(obj)
        obj.endpoints.each do |endpoint|
          original_block = endpoint.block

          endpoint.block = lambda do |*args, &block|
            env = args.first.env['api.endpoint']

            begin
              response = catch(:error) do
                # Definitely counter-intuitive to pass `endpoint` to this method, but
                # grape's insane metaprogramming spaghetti leaves us no choice.
                # See: https://github.com/intridea/grape/blob/v0.9.0/lib/grape/endpoint.rb#L38
                #
                # Basically, grape uses define_method to construct a new method for
                # each endpoint. It then grabs a reference to the method via a call to
                # instance_method, which returns a ruby Method object (fyi Method objects
                # can be dynamically bound to objects of the same type). Grape then deletes
                # the method it just defined and returns a proc that wraps the Method object.
                # The wrapping proc takes a single argument, which is expected to be an
                # instance of the Endpoint class. The body of the proc binds the Method object
                # to the passed Endpoint instance and calls it (with no arguments). Any sane
                # implementation would accept the args the original endpoint method accepts,
                # but those original args are hidden by the dynamic method re-bind. What this
                # means is the arguments passed to the lambda here in this method (look up)
                # ARE THE SAME EXACT ARGUMENTS that `endpoint` receives. All of this explains
                # why we pass `endpoint` here instead of *args and &block from the above lambda.
                # Kids: don't try this at home.
                original_block.call(endpoint)
              end

              if response.fetch(:status, 200) >= 400
                configuration.rollbar_notifier.error(
                  response.fetch(:message, {}).fetch(:error, 'Unknown error'),
                  env.params, env.headers
                )

                # re-throw (we just do logging, let middleware handle this error)
                throw :error, response
              end

              response
            rescue => e
              configuration.rollbar_notifier.error(e, env.params, env.headers)

              # re-raise (we just do logging, let middleware handle this error)
              raise e
            end
          end
        end
      end
    end

  end
end
