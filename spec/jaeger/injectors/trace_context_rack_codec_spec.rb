require 'spec_helper'

describe Jaeger::Injectors::TraceContextRackCodec do
  let(:tracer) do
    Jaeger::Tracer.new(
      reporter: instance_spy(Jaeger::Reporters::RemoteReporter),
      sampler: Jaeger::Samplers::Const.new(true),
      injectors: Jaeger::Injectors.prepare({}),
      extractors: Jaeger::Extractors.prepare({})
    )
  end
  let(:span) { tracer.start_span('test') }

  it 'sets traceparent' do
    span_context = build_span_context(
      trace_id: 943_123_332_103_493_452_342_394_253,
      span_id: 4_324_323_423_423_123,
      flags: Jaeger::SpanContext::Flags::SAMPLED
    )

    carrier = {}
    described_class.inject(span_context, carrier)

    expect(carrier['traceparent']).to eq('00-00000000030c22224787fd223b027d8d-000f5cf3018c0a93-01')
  end

  it 'sets traceparent with largest trace id and span id' do
    span_context = build_span_context(
      trace_id: (2**128) - 1,
      span_id: (2**64) - 1,
      flags: Jaeger::SpanContext::Flags::SAMPLED
    )

    carrier = {}
    described_class.inject(span_context, carrier)

    expect(carrier['traceparent']).to eq('00-ffffffffffffffffffffffffffffffff-ffffffffffffffff-01')
  end

  def inject(span, carrier)
    described_class.inject(span.context, carrier)
  end
end
