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
          # Grape::Endpoint.send(:include, endpoint.send(:helpers))
          original_block = endpoint.block

          endpoint.block = lambda do |*args, &block|
            env = args.first.env['api.endpoint']

            begin
              response = catch(:error) do
                # Definitely counter-intuitive to pass `env` to this method, but
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
                # ARE THE SAME EXACT ARGUMENTS that `env` indirectly receives. All of this explains
                # why we pass `env` here instead of *args and &block from the above lambda. We
                # can't pass `endpoint` because methods from `helper` blocks and parameters from
                # `params` don't get mixed into the endpoint until the endpoint actually gets
                # called, meaning there's a big difference in the interface between the endpoint
                # as it's stored in `obj.endpoints` and the interface available when the endpoint
                # gets executed. Kids: don't try this at home.
                original_block.call(env)
              end

              if is_error_response?(response)
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

      def get_error_status(response)
        if response.is_a?(Hash)
          status = response.fetch(:status, 200)

          case status
            when String
              status.to_i if status =~ /[\d]+/
            when Fixnum
              status
          end
        end
      end

      def is_error_response?(response)
        if status = get_error_status(response)
          status >= 400
        else
          false
        end
      end
    end

  end
end
