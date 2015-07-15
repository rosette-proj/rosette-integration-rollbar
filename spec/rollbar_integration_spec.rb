# encoding: UTF-8

require 'spec_helper'

include Rosette::Integrations

describe RollbarIntegration do
  let(:fake_grape_api) do
    Class.new(Grape::API) do
      get :success do
        '{"foo": "bar"}'
      end

      get :failure do
        error!({ error: 'Broken!!!' }, 500)
      end
    end
  end

  describe '#configure' do
    it 'yields an integration configurator and returns a new integration instance' do
      integration = RollbarIntegration.configure do |integration_config|
        expect(integration_config).to be_a(RollbarIntegration::Configurator)
        integration_config.set_rollbar_notifier(:foobar)
      end

      expect(integration).to be_a(RollbarIntegration)
      expect(integration.configuration.rollbar_notifier).to eq(:foobar)
    end
  end

  describe '#integrate' do
    let(:integration) do
      RollbarIntegration.configure
    end

    it 'integrates with a rosette configurator' do
      rosette_config = Rosette.build_config { }
      integration.integrate(rosette_config)
      expect(rosette_config.error_reporter).to be_a(
        RollbarIntegration::RollbarErrorReporter
      )
    end

    it 'integrates with a grape api class by replacing the endpoint lambdas' do
      expect(fake_grape_api.endpoints.size).to be > 0

      endpoint_lambda_object_ids = fake_grape_api.endpoints.map do |ep|
        ep.block.object_id
      end

      integration.integrate(fake_grape_api)

      new_endpoint_lambda_object_ids = fake_grape_api.endpoints.map do |ep|
        ep.block.object_id
      end

      expect(endpoint_lambda_object_ids).to_not eq(
        new_endpoint_lambda_object_ids
      )
    end

    it 'raises an error if not able to integrate' do
      expect { integration.integrate(1) }.to(
        raise_error(Errors::ImpossibleIntegrationError)
      )
    end
  end

  describe '#integrates_with?' do
    let(:integration) do
      RollbarIntegration.configure
    end

    it 'returns true if the integration is possible' do
      expect(integration.integrates_with?(fake_grape_api)).to eq(true)
    end

    it 'returns false if the integration is impossible' do
      expect(integration.integrates_with?(1)).to eq(false)
    end
  end

  context 'when integrated into a grape api class' do
    include Rack::Test::Methods

    def app
      fake_grape_api
    end

    let(:notifier) { double(:notifier) }
    let(:integration) do
      RollbarIntegration.configure do |integration_config|
        integration_config.set_rollbar_notifier(notifier)
      end
    end

    before(:each) do
      integration.integrate(fake_grape_api)
    end

    it 'does not report errors on successful grape responses' do
      get :success
      expect(last_response.status).to eq(200)
    end

    it 'reports errors in unsuccessful grape responses' do
      expect(notifier).to(
        receive(:error).with('Broken!!!', an_instance_of(Hash))
      )

      get :failure
      expect(last_response.status).to eq(500)
    end

    it 'does not report errors in unsuccessful grape responses if explicitly disabled' do
      integration.configuration.should_log_expected_errors(false)
      expect(notifier).to_not receive(:error)

      get :failure
      expect(last_response.status).to eq(500)
    end

    it 'reports unhandled errors and re-raises' do
      # cause a bogus error somewhere in the endpoint
      allow(integration).to(
        receive(:is_error_response?).and_raise(StandardError)
      )

      expect(notifier).to(
        receive(:error).with(StandardError, an_instance_of(Hash))
      )

      expect { get :success }.to raise_error(StandardError)
    end

    it 'reports unhandled java exceptions' do
      exception_class = Java::JavaLang::IllegalArgumentException

      # cause a bogus error somewhere in the endpoint
      allow(integration).to(
        receive(:is_error_response?).and_raise(exception_class.new('Broken'))
      )

      expect(notifier).to(
        receive(:error).with(
          an_instance_of(exception_class), an_instance_of(Hash)
        )
      )

      expect { get :success }.to raise_error(exception_class)
    end
  end
end
