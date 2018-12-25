require 'spec_helper'

RSpec.describe Jaeger::Client::Reporters::CompositeReporter do
  let(:reporter) { described_class.new(reporters: [reporter1, reporter2]) }
  let(:reporter1) { instance_spy(Jaeger::Client::Reporters::InMemoryReporter) }
  let(:reporter2) { instance_spy(Jaeger::Client::Reporters::RemoteReporter) }

  describe '#report' do
    it 'forwards span to all reporters' do
      span = build_span
      reporter.report(span)

      expect(reporter1).to have_received(:report).with(span)
      expect(reporter2).to have_received(:report).with(span)
    end
  end
end
