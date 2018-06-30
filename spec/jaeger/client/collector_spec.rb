require 'spec_helper'

RSpec.describe Jaeger::Client::Collector do
  let(:collector) { described_class.new }
  let(:operation_name) { 'op-name' }

  describe '#send_span' do
    let(:context) do
      Jaeger::Client::SpanContext.new(
        trace_id: Jaeger::Client::TraceId.generate,
        span_id: Jaeger::Client::TraceId.generate,
        flags: flags
      )
    end
    let(:span) { Jaeger::Client::Span.new(context, operation_name, collector) }

    context 'when span has debug mode enabled' do
      let(:flags) { Jaeger::Client::SpanContext::Flags::DEBUG }

      it 'buffers the span' do
        collector.send_span(span, Time.now)
        expect(collector.retrieve).not_to be_empty
      end
    end

    context 'when span is sampled' do
      let(:flags) { Jaeger::Client::SpanContext::Flags::SAMPLED }

      it 'buffers the span' do
        collector.send_span(span, Time.now)
        expect(collector.retrieve).not_to be_empty
      end
    end

    context 'when span does not have debug mode nor is sampled' do
      let(:flags) { Jaeger::Client::SpanContext::Flags::NONE }

      it 'does not buffer the span' do
        collector.send_span(span, Time.now)
        expect(collector.retrieve).to be_empty
      end
    end
  end
end
