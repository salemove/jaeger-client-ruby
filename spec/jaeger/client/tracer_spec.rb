require 'spec_helper'

describe Jaeger::Client::Tracer do
  let(:tracer) { described_class.new(collector, sender, sampler) }
  let(:collector) { instance_spy(Jaeger::Client::Collector) }
  let(:sender) { spy }
  let(:sampler) { Jaeger::Client::Samplers::Const.new(true) }

  context 'when using #extract and #inject' do
    UBER_TRACE_IDS = %w[
      c94f3977ee9a073:69548f7c197ab707:10bc37238fcf6732:1
      7ee9a073:69548f7c197ab707:10bc37238fcf6732:1
      ffffffffffffffff:69548f7c197ab707:10bc37238fcf6732:1
      -1:69548f7c197ab707:10bc37238fcf6732:1
      -10000000000000001:69548f7c197ab707:10bc37238fcf6732:1
      7fffffffffffffff:69548f7c197ab707:10bc37238fcf6732:1
      5288f24bd7783293:69548f7c197ab707:10bc37238fcf6732:1
      6e7c7815b3ba63b9dd8c8687003a4ff1:69548f7c197ab707:10bc37238fcf6732:1
      7815b3ba63b9dd8c8687003a4ff1:69548f7c197ab707:10bc37238fcf6732:1
    ].freeze

    UBER_TRACE_IDS.each do |uti|
      it "uber-trace-id: #{uti} is the same" do
        carrier = { 'uber-trace-id' => uti.dup }
        span_context = tracer.extract(OpenTracing::FORMAT_TEXT_MAP, carrier)
        tracer.inject(span_context, OpenTracing::FORMAT_TEXT_MAP, carrier)

        expect(carrier['uber-trace-id']).to eq(uti)
      end
    end
  end

  describe '#start_span' do
    let(:operation_name) { 'operator-name' }

    context 'when a root span' do
      let(:span) { tracer.start_span(operation_name) }

      describe 'span context' do
        it 'has span_id' do
          expect(span.context.span_id).not_to be_nil
        end

        it 'has trace_id' do
          expect(span.context.trace_id).not_to be_nil
        end

        it 'does not have parent' do
          expect(span.context.parent_id).to eq(0)
        end
      end
    end

    context 'when a child span context is provided' do
      let(:root_span) { tracer.start_span(root_operation_name) }
      let(:span) { tracer.start_span(operation_name, child_of: root_span.context) }
      let(:root_operation_name) { 'root-operation-name' }

      describe 'span context' do
        it 'has span_id' do
          expect(span.context.span_id).not_to be_nil
        end

        it 'has trace_id' do
          expect(span.context.trace_id).not_to be_nil
        end

        it 'does not have parent_id' do
          expect(span.context.parent_id).not_to eq(0)
        end
      end
    end

    context 'when a child span is provided' do
      let(:root_span) { tracer.start_span(root_operation_name) }
      let(:span) { tracer.start_span(operation_name, child_of: root_span) }
      let(:root_operation_name) { 'root-operation-name' }

      describe 'span context' do
        it 'has span_id' do
          expect(span.context.span_id).not_to be_nil
        end

        it 'has trace_id' do
          expect(span.context.trace_id).not_to be_nil
        end

        it 'does not have parent_id' do
          expect(span.context.parent_id).not_to eq(0)
        end
      end
    end
  end

  describe '#start_active_span' do
    let(:operation_name) { 'operator-name' }

    context 'when a root span' do
      let(:scope) { tracer.start_active_span(operation_name) }
      let(:span) { scope.span }

      describe 'span context' do
        it 'has span_id' do
          expect(span.context.span_id).not_to be_nil
        end

        it 'has trace_id' do
          expect(span.context.trace_id).not_to be_nil
        end

        it 'does not have parent_id' do
          expect(span.context.parent_id).to eq(0)
        end
      end
    end

    context 'when a child span context is provided' do
      let(:root_span) { tracer.start_span(root_operation_name) }
      let(:scope) { tracer.start_active_span(operation_name, child_of: root_span.context) }
      let(:span) { scope.span }
      let(:root_operation_name) { 'root-operation-name' }

      describe 'span context' do
        it 'has span_id' do
          expect(span.context.span_id).not_to be_nil
        end

        it 'has trace_id' do
          expect(span.context.trace_id).not_to be_nil
        end

        it 'does not have parent_id' do
          expect(span.context.parent_id).not_to eq(0)
        end
      end
    end

    context 'when a child span is provided' do
      let(:root_span) { tracer.start_span(root_operation_name) }
      let(:scope) { tracer.start_active_span(operation_name, child_of: root_span) }
      let(:span) { scope.span }
      let(:root_operation_name) { 'root-operation-name' }

      describe 'span context' do
        it 'has span_id' do
          expect(span.context.span_id).not_to be_nil
        end

        it 'has trace_id' do
          expect(span.context.trace_id).not_to be_nil
        end

        it 'does not have parent_id' do
          expect(span.context.parent_id).not_to eq(0)
        end
      end
    end

    context 'when already existing active span' do
      let(:root_operation_name) { 'root-operation-name' }

      it 'uses active span as a parent span' do
        tracer.start_active_span(root_operation_name) do |parent_scope|
          tracer.start_active_span(operation_name) do |scope|
            expect(scope.span.context.parent_id).to eq(parent_scope.span.context.span_id)
          end
        end
      end
    end
  end

  describe '#active_span' do
    let(:root_operation_name) { 'root-operation-name' }
    let(:operation_name) { 'operation-name' }

    it 'returns the span of the active scope' do
      expect(tracer.active_span).to eq(nil)

      tracer.start_active_span(root_operation_name) do |parent_scope|
        expect(tracer.active_span).to eq(parent_scope.span)

        tracer.start_active_span(operation_name) do |scope|
          expect(tracer.active_span).to eq(scope.span)
        end

        expect(tracer.active_span).to eq(parent_scope.span)
      end

      expect(tracer.active_span).to eq(nil)
    end
  end

  describe '#inject' do
    let(:operation_name) { 'operator-name' }
    let(:span) { tracer.start_span(operation_name) }
    let(:span_context) { span.context }
    let(:carrier) { {} }

    context 'when FORMAT_TEXT_MAP' do
      before { tracer.inject(span_context, OpenTracing::FORMAT_TEXT_MAP, carrier) }

      it 'sets trace information' do
        expect(carrier['uber-trace-id']).to eq(
          [
            span_context.trace_id.to_s(16),
            span_context.span_id.to_s(16),
            span_context.parent_id.to_s(16),
            span_context.flags.to_s(16)
          ].join(':')
        )
      end
    end
  end

  describe '#extract' do
    let(:hexa_negative_int64) { 'ffffffffffffffff' } # -1
    let(:hexa_positive_int64) { '7fffffffffffffff' } # max positive

    let(:operation_name) { 'operator-name' }
    let(:trace_id) { '58a515c97fd61fd7' }
    let(:parent_id) { '8e5a8c5509c8dcc1' }
    let(:span_id) { 'aba8be8d019abed2' }
    let(:flags) { '1' }

    context 'when FORMAT_TEXT_MAP' do
      let(:carrier) { { 'uber-trace-id' => "#{trace_id}:#{span_id}:#{parent_id}:#{flags}" } }
      let(:span_context) { tracer.extract(OpenTracing::FORMAT_TEXT_MAP, carrier) }

      it 'has flags' do
        expect(span_context.flags).to eq(flags.to_i(16))
      end

      context 'when trace-id is a negative int64' do
        let(:trace_id) { hexa_negative_int64 }

        it 'interprets it correctly' do
          expect(span_context.trace_id).to eq(hexa_negative_int64.to_i(16))
        end
      end

      context 'when trace-id is a positive int64' do
        let(:trace_id) { hexa_positive_int64 }

        it 'interprets it correctly' do
          expect(span_context.trace_id).to eq(2**63 - 1)
        end
      end

      context 'when parent-id is a negative int64' do
        let(:parent_id) { hexa_negative_int64 }

        it 'interprets it correctly' do
          expect(span_context.parent_id).to eq(hexa_negative_int64.to_i(16))
        end
      end

      context 'when parent-id is a positive int64' do
        let(:parent_id) { hexa_positive_int64 }

        it 'interprets it correctly' do
          expect(span_context.parent_id).to eq(2**63 - 1)
        end
      end

      context 'when span-id is a negative int64' do
        let(:span_id) { hexa_negative_int64 }

        it 'interprets it correctly' do
          expect(span_context.span_id).to eq(hexa_negative_int64.to_i(16))
        end
      end

      context 'when span-id is a positive int64' do
        let(:span_id) { hexa_positive_int64 }

        it 'interprets it correctly' do
          expect(span_context.span_id).to eq(2**63 - 1)
        end
      end

      context 'when parent-id is 0' do
        let(:parent_id) { '0' }

        it 'sets parent_id to 0' do
          expect(span_context.parent_id).to eq(0)
        end
      end

      context 'when trace-id missing' do
        let(:trace_id) { nil }

        it 'returns nil' do
          expect(span_context).to eq(nil)
        end
      end

      context 'when span-id missing' do
        let(:span_id) { nil }

        it 'returns nil' do
          expect(span_context).to eq(nil)
        end
      end
    end

    context 'when FORMAT_RACK' do
      let(:carrier) { { 'HTTP_UBER_TRACE_ID' => "#{trace_id}:#{span_id}:#{parent_id}:#{flags}" } }
      let(:span_context) { tracer.extract(OpenTracing::FORMAT_RACK, carrier) }

      it 'has flags' do
        expect(span_context.flags).to eq(flags.to_i(16))
      end

      context 'when trace-id is a negative int64' do
        let(:trace_id) { hexa_negative_int64 }

        it 'interprets it correctly' do
          expect(span_context.trace_id).to eq(hexa_negative_int64.to_i(16))
        end
      end

      context 'when trace-id is a positive int64' do
        let(:trace_id) { hexa_positive_int64 }

        it 'interprets it correctly' do
          expect(span_context.trace_id).to eq(2**63 - 1)
        end
      end

      context 'when parent-id is a negative int64' do
        let(:parent_id) { hexa_negative_int64 }

        it 'interprets it correctly' do
          expect(span_context.parent_id).to eq(hexa_negative_int64.to_i(16))
        end
      end

      context 'when parent-id is a positive int64' do
        let(:parent_id) { hexa_positive_int64 }

        it 'interprets it correctly' do
          expect(span_context.parent_id).to eq(2**63 - 1)
        end
      end

      context 'when span-id is a negative int64' do
        let(:span_id) { hexa_negative_int64 }

        it 'interprets it correctly' do
          expect(span_context.span_id).to eq(hexa_negative_int64.to_i(16))
        end
      end

      context 'when span-id is a positive int64' do
        let(:span_id) { hexa_positive_int64 }

        it 'interprets it correctly' do
          expect(span_context.span_id).to eq(2**63 - 1)
        end
      end

      context 'when parent-id is 0' do
        let(:parent_id) { '0' }

        it 'sets parent_id to 0' do
          expect(span_context.parent_id).to eq(0)
        end
      end

      context 'when trace-id is missing' do
        let(:trace_id) { nil }

        it 'returns nil' do
          expect(span_context).to eq(nil)
        end
      end

      context 'when span-id is missing' do
        let(:span_id) { nil }

        it 'returns nil' do
          expect(span_context).to eq(nil)
        end
      end
    end
  end
end
