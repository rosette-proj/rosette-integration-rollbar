# encoding: UTF-8

require 'spec_helper'

include Rosette::Integrations

describe RollbarIntegration::RollbarErrorReporter do
  let(:notifier) { double(:notifier) }
  let(:reporter) { RollbarIntegration::RollbarErrorReporter.new(notifier) }

  let(:error) do
    begin
      raise StandardError, 'testing'
    rescue => e
      e
    end
  end

  let(:exception) do
    begin
      raise Java::JavaLang::IllegalArgumentException.new('testing')
    rescue => e
      e
    end
  end

  describe '#report_error' do
    it 'passes the exception through to the notifier' do
      expect(notifier).to receive(:error).with(error, {})
      reporter.report_error(error)
    end

    it 'wraps java errors before reporting them' do
      expect(notifier).to(
        receive(:error).with(
          an_instance_of(RollbarIntegration::JavaException), {}
        )
      )

      reporter.report_error(exception)
    end
  end

  describe '#report_warning' do
    it 'passes the exception through to the notifier' do
      expect(notifier).to receive(:warn).with(error, {})
      reporter.report_warning(error)
    end

    it 'wraps java errors before reporting them' do
      expect(notifier).to(
        receive(:warn).with(
          an_instance_of(RollbarIntegration::JavaException), {}
        )
      )

      reporter.report_warning(exception)
    end
  end
end
