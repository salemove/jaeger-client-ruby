require 'spec_helper'

describe Jaeger::Injectors::JaegerRackCodec do
  let(:tracer) do
    Jaeger::Tracer.new(
      reporter: instance_spy(Jaeger::Reporters::RemoteReporter),
      sampler: Jaeger::Samplers::Const.new(true),
      injectors: Jaeger::Injectors.prepare({}),
      extractors: Jaeger::Extractors.prepare({})
    )
  end
  let(:span) { tracer.start_span('test') }

  it 'sets trace information' do
    carrier = {}
    inject(span, carrier)

    expect(carrier['uber-trace-id']).to eq(
      [
        span.context.trace_id.to_s(16),
        span.context.span_id.to_s(16),
        span.context.parent_id.to_s(16),
        span.context.flags.to_s(16)
      ].join('%3A')
    )
  end

  it 'sets baggage' do
    span.set_baggage_item('foo', 'bar')
    span.set_baggage_item('x', 'y')
    carrier = {}
    inject(span, carrier)

    expect(carrier['uberctx-foo']).to eq('bar')
    expect(carrier['uberctx-x']).to eq('y')
  end

  def inject(span, carrier)
    described_class.inject(span.context, carrier)
  end
end
