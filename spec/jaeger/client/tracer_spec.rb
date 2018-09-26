require 'spec_helper'

describe Jaeger::Client::Tracer do
  let(:tracer) { described_class.new(reporter, sampler) }
  let(:reporter) { instance_spy(Jaeger::Client::AsyncReporter) }
  let(:sampler) { Jaeger::Client::Samplers::Const.new(true) }

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
    let(:hexa_max_uint64) { 'ff' * 8 }
    let(:max_uint64) { 2**64 - 1 }

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

      context 'when trace-id is a max uint64' do
        let(:trace_id) { hexa_max_uint64 }

        it 'interprets it correctly' do
          expect(span_context.trace_id).to eq(max_uint64)
        end
      end

      context 'when parent-id is a max uint64' do
        let(:parent_id) { hexa_max_uint64 }

        it 'interprets it correctly' do
          expect(span_context.parent_id).to eq(max_uint64)
        end
      end

      context 'when span-id is a max uint64' do
        let(:span_id) { hexa_max_uint64 }

        it 'interprets it correctly' do
          expect(span_context.span_id).to eq(max_uint64)
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

      context 'when trace-id is a max uint64' do
        let(:trace_id) { hexa_max_uint64 }

        it 'interprets it correctly' do
          expect(span_context.trace_id).to eq(max_uint64)
        end
      end

      context 'when parent-id is a max uint64' do
        let(:parent_id) { hexa_max_uint64 }

        it 'interprets it correctly' do
          expect(span_context.parent_id).to eq(max_uint64)
        end
      end

      context 'when span-id is a max uint64' do
        let(:span_id) { hexa_max_uint64 }

        it 'interprets it correctly' do
          expect(span_context.span_id).to eq(max_uint64)
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
