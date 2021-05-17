require 'spec_helper'

RSpec::Matchers.define :be_a_valid_thrift_span do |_|
  match do |actual|
    actual.instance_of?(::Jaeger::Thrift::Span) &&
      !actual.instance_variable_get(:@traceIdLow).nil? &&
      !actual.instance_variable_get(:@traceIdHigh).nil? &&
      !actual.instance_variable_get(:@spanId).nil? &&
      !actual.instance_variable_get(:@parentSpanId).nil? &&
      !actual.instance_variable_get(:@operationName).nil? &&
      !actual.instance_variable_get(:@flags).nil? &&
      !actual.instance_variable_get(:@startTime).nil? &&
      !actual.instance_variable_get(:@duration).nil? &&
      !actual.instance_variable_get(:@tags).nil?
  end
end

RSpec.describe Jaeger::Encoders::ThriftEncoder do
  let(:encoder) { described_class.new(service_name: service_name, tags: tags) }
  let(:service_name) { 'service-name' }
  let(:tags) { {} }

  context 'without custom tags' do
    it 'has jaeger.version' do
      tags = encoder.encode([]).process.tags
      version_tag = tags.detect { |tag| tag.key == 'jaeger.version' }
      expect(version_tag.vStr).to match(/Ruby-/)
    end

    it 'has hostname' do
      tags = encoder.encode([]).process.tags
      hostname_tag = tags.detect { |tag| tag.key == 'hostname' }
      expect(hostname_tag.vStr).to be_a(String)
    end

    it 'has ip' do
      tags = encoder.encode([]).process.tags
      ip_tag = tags.detect { |tag| tag.key == 'ip' }
      expect(ip_tag.vStr).to be_a(String)
    end
  end

  context 'when hostname is provided' do
    let(:tags) { { 'hostname' => hostname } }
    let(:hostname) { 'custom-hostname' }

    it 'uses provided hostname in the process tags' do
      tags = encoder.encode([]).process.tags
      hostname_tag = tags.detect { |tag| tag.key == 'hostname' }
      expect(hostname_tag.vStr).to eq(hostname)
    end
  end

  context 'when ip is provided' do
    let(:tags) { { 'ip' => ip } }
    let(:ip) { 'custom-ip' }

    it 'uses provided ip in the process tags' do
      tags = encoder.encode([]).process.tags
      ip_tag = tags.detect { |tag| tag.key == 'ip' }
      expect(ip_tag.vStr).to eq(ip)
    end
  end

  context 'when spans are encoded without limit' do
    let(:context) do
      Jaeger::SpanContext.new(
        trace_id: Jaeger::TraceId.generate,
        span_id: Jaeger::TraceId.generate,
        flags: Jaeger::SpanContext::Flags::DEBUG
      )
    end
    let(:example_span) { Jaeger::Span.new(context, 'example_op', nil) }

    it 'encodes spans into one batch' do
      encoded_batch = encoder.encode([example_span])
      expect(encoded_batch.spans.first).to be_a_valid_thrift_span
    end
  end

  context 'when spans are encoded with limits' do
    let(:context) do
      Jaeger::SpanContext.new(
        trace_id: Jaeger::TraceId.generate,
        span_id: Jaeger::TraceId.generate,
        flags: Jaeger::SpanContext::Flags::DEBUG
      )
    end
    let(:example_span) { Jaeger::Span.new(context, 'example_op', nil) }
    # example span have size of 63, so let's make an array of 100 span
    # and set the limit at 5000, so it should return a batch of 2
    let(:example_spans) { Array.new(100, example_span) }

    it 'encodes spans into multiple batches' do
      encoded_batches = encoder.encode_limited_size(example_spans, ::Thrift::CompactProtocol, 5_000)
      expect(encoded_batches.length).to be(2)
      expect(encoded_batches.first.spans.first).to be_a_valid_thrift_span
      expect(encoded_batches.first.spans.last).to be_a_valid_thrift_span
      expect(encoded_batches.last.spans.first).to be_a_valid_thrift_span
      expect(encoded_batches.last.spans.last).to be_a_valid_thrift_span
    end
  end

  context 'when span have reference' do
    let(:context) do
      Jaeger::SpanContext.new(
        trace_id: Jaeger::TraceId.generate,
        span_id: Jaeger::TraceId.generate,
        flags: Jaeger::SpanContext::Flags::DEBUG
      )
    end
    let(:reference_context) do
      Jaeger::SpanContext.new(
        trace_id: rand(Jaeger::TraceId::MAX_128BIT_UNSIGNED_INT),
        span_id: Jaeger::TraceId.generate,
        flags: Jaeger::SpanContext::Flags::DEBUG
      )
    end
    let(:example_references) { [OpenTracing::Reference.follows_from(reference_context)] }
    let(:example_span) { Jaeger::Span.new(context, 'example_op', nil, references: example_references) }
    let(:example_spans) { [example_span] }

    it 'encode span with references' do
      batch = encoder.encode(example_spans)
      span = batch.spans.first
      reference = span.references.first

      trace_id_half_range = [-Jaeger::TraceId::MAX_64BIT_SIGNED_INT, Jaeger::TraceId::MAX_64BIT_SIGNED_INT]
      expect(reference.traceIdLow).to be_between(*trace_id_half_range)
      expect(reference.traceIdHigh).to be_between(*trace_id_half_range)
      expect(reference.traceIdLow).not_to eq 0
      expect(reference.traceIdHigh).not_to eq 0
    end
  end
end
