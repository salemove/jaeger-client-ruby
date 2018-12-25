require 'spec_helper'

RSpec.describe Jaeger::Client::Reporters::InMemoryReporter do
  let(:reporter) { described_class.new }

  describe '#report' do
    it 'adds span to in memory spans list' do
      span1 = build_span
      span2 = build_span

      reporter.report(span1)
      reporter.report(span2)

      expect(reporter.spans).to eq([span1, span2])
    end
  end

  describe '#clear' do
    it 'clears spans from the reporter' do
      span1 = build_span
      reporter.report(span1)

      reporter.clear

      span2 = build_span
      reporter.report(span2)

      expect(reporter.spans).to eq([span2])
    end
  end
end
