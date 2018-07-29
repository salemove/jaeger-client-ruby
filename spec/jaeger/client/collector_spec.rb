require 'spec_helper'

RSpec.describe Jaeger::Client::Collector do
  let(:collector) { described_class.new }
  let(:operation_name) { 'op-name' }

  describe '#send_span' do
    let(:trace_id) { Jaeger::Client::TraceId.generate }
    let(:span_id) { Jaeger::Client::TraceId.generate }
    let(:parent_id) { Jaeger::Client::TraceId.generate }
    let(:flags) { Jaeger::Client::SpanContext::Flags::SAMPLED }
    let(:context) do
      Jaeger::Client::SpanContext.new(
        trace_id: trace_id,
        span_id: span_id,
        parent_id: parent_id,
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

    context 'parsing ids for thrift specific sizes' do
      # on 64-bits you can actually put 18446744073709551616 numbers
      # thrift support sending -9223372036854775808 to 9223372036854775807
      let(:hexa_negative_int64) { 18446744073709551615 } # -1
      let(:hexa_positive_int64) { 9223372036854775807 } # max positive

      before do
        allow(Jaeger::Thrift::Span).to receive(:new).and_call_original

        collector.send_span(span, Time.now)
      end

      context 'when trace-id is a negative int64' do
        let(:trace_id) { hexa_negative_int64 }

        it 'interprets it correctly' do
          expect(Jaeger::Thrift::Span).to have_received(:new).with(hash_including('traceIdLow' => -1))
        end
      end

      context 'when trace-id is a positive int64' do
        let(:trace_id) { hexa_positive_int64 }

        it 'interprets it correctly' do
          expect(Jaeger::Thrift::Span).to have_received(:new).with(hash_including('traceIdLow' => 2**63 - 1))
        end
      end

      context 'when parent-id is a negative int64' do
        let(:parent_id) { hexa_negative_int64 }

        it 'interprets it correctly' do
          expect(Jaeger::Thrift::Span).to have_received(:new).with(hash_including('parentSpanId' => -1))
        end
      end

      context 'when parent-id is a positive int64' do
        let(:parent_id) { hexa_positive_int64 }

        it 'interprets it correctly' do
          expect(Jaeger::Thrift::Span).to have_received(:new).with(hash_including('parentSpanId' => 2**63 - 1))
        end
      end

      context 'when span-id is a negative int64' do
        let(:span_id) { hexa_negative_int64 }

        it 'interprets it correctly' do
          expect(Jaeger::Thrift::Span).to have_received(:new).with(hash_including('spanId' => -1))
        end
      end

      context 'when span-id is a positive int64' do
        let(:span_id) { hexa_positive_int64 }

        it 'interprets it correctly' do
          expect(Jaeger::Thrift::Span).to have_received(:new).with(hash_including('spanId' => 2**63 - 1))
        end
      end
    end
  end
end
