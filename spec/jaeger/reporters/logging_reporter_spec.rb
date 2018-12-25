require 'spec_helper'

RSpec.describe Jaeger::Reporters::LoggingReporter do
  let(:reporter) { described_class.new(logger: logger) }
  let(:logger) { instance_spy(Logger) }

  describe '#report' do
    it 'logs out span information' do
      operation_name = 'my-op-name'
      start_time = Time.utc(2018, 11, 10, 15, 24, 30)
      end_time = Time.utc(2018, 11, 10, 15, 24, 33)

      span = build_span(operation_name: operation_name, start_time: start_time)
      span.finish(end_time: end_time)
      reporter.report(span)

      expect(logger).to have_received(:info).with(
        <<-STR.gsub(/\s+/, ' ').strip
          Span reported: {:operation_name=>"#{operation_name}",
          :start_time=>"#{start_time.iso8601}",
          :end_time=>"#{end_time.iso8601}",
          :trace_id=>"#{span.context.to_trace_id}",
          :span_id=>"#{span.context.to_span_id}"}
        STR
      )
    end
  end
end
