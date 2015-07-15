# encoding: UTF-8

require 'spec_helper'

include Rosette::Integrations

describe RollbarIntegration::JavaException do
  let(:exception) do
    begin
      raise Java::JavaLang::IllegalArgumentException.new('testing')
    rescue => e
      e
    end
  end

  let(:java_exception) do
    RollbarIntegration::JavaException.new(exception)
  end

  describe '#backtrace' do
    it 'returns the backtrace for the underlying exception' do
      backtrace = java_exception.backtrace
      expect(backtrace).to be_a(Array)
      expect(backtrace.size).to be > 0
    end
  end

  describe '#message' do
    it 'prints out a formatted message' do
      expect(java_exception.message).to eq(
        '<Java::JavaLang::IllegalArgumentException> testing'
      )
    end
  end
end
