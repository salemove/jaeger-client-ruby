require 'spec_helper'

describe Jaeger::Tracer do
  let(:tracer) do
    described_class.new(
      reporter: reporter,
      sampler: sampler,
      injectors: Jaeger::Injectors.prepare(injectors),
      extractors: Jaeger::Extractors.prepare(extractors)
    )
  end
  let(:reporter) { instance_spy(Jaeger::Reporters::RemoteReporter) }
  let(:sampler) { Jaeger::Samplers::Const.new(true) }
  let(:injectors) { {} }
  let(:extractors) { {} }

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

    context 'when default injectors' do
      it 'calls inject on JaegerTextMapCodec when FORMAT_TEXT_MAP' do
        expect(Jaeger::Injectors::JaegerTextMapCodec).to receive(:inject)
          .with(span_context, carrier)
        tracer.inject(span_context, OpenTracing::FORMAT_TEXT_MAP, carrier)
      end

      it 'calls inject on JaegerRackCodec when FORMAT_RACK' do
        expect(Jaeger::Injectors::JaegerRackCodec).to receive(:inject)
          .with(span_context, carrier)
        tracer.inject(span_context, OpenTracing::FORMAT_RACK, carrier)
      end
    end

    context 'when custom injectors' do
      let(:injectors) do
        { OpenTracing::FORMAT_RACK => [custom_injector1, custom_injector2] }
      end
      let(:custom_injector1) { class_double(Jaeger::Injectors::JaegerTextMapCodec, inject: nil) }
      let(:custom_injector2) { class_double(Jaeger::Injectors::JaegerTextMapCodec, inject: nil) }

      it 'calls all custom injectors' do
        tracer.inject(span_context, OpenTracing::FORMAT_RACK, carrier)

        expect(custom_injector1).to have_received(:inject).with(span_context, carrier)
        expect(custom_injector2).to have_received(:inject).with(span_context, carrier)
      end
    end
  end

  describe '#extract' do
    let(:carrier) { {} }
    let(:span_context) { instance_double(Jaeger::SpanContext) }

    context 'when default extractors' do
      it 'calls extract on JaegerTextMapCodec when FORMAT_TEXT_MAP' do
        allow(Jaeger::Extractors::JaegerTextMapCodec).to receive(:extract)
          .with(carrier)
          .and_return(span_context)
        expect(tracer.extract(OpenTracing::FORMAT_TEXT_MAP, carrier)).to eq(span_context)
      end

      it 'calls extract on JaegerRackCodec when FORMAT_RACK' do
        allow(Jaeger::Extractors::JaegerRackCodec).to receive(:extract)
          .with(carrier)
          .and_return(span_context)
        expect(tracer.extract(OpenTracing::FORMAT_RACK, carrier)).to eq(span_context)
      end
    end

    context 'when custom extractors' do
      let(:extractors) do
        { OpenTracing::FORMAT_RACK => [custom_extractor1, custom_extractor2] }
      end
      let(:custom_extractor1) { double }
      let(:custom_extractor2) { double }

      it 'calls all custom extractors when no results' do
        allow(custom_extractor1).to receive(:extract).with(carrier).and_return(nil)
        allow(custom_extractor2).to receive(:extract).with(carrier).and_return(nil)
        expect(tracer.extract(OpenTracing::FORMAT_RACK, carrier)).to eq(nil)

        expect(custom_extractor1).to have_received(:extract)
        expect(custom_extractor2).to have_received(:extract)
      end

      it 'returns result from the first matching extractor' do
        allow(custom_extractor1).to receive(:extract).with(carrier) { span_context }
        expect(tracer.extract(OpenTracing::FORMAT_RACK, carrier)).to eq(span_context)
      end
    end
  end
end
