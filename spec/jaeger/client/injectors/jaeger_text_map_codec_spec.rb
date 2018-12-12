require 'spec_helper'

describe Jaeger::Client::Injectors::JaegerTextMapCodec do
  let(:inject) { described_class.inject(span_context, carrier) }

  let(:span_context) { Jaeger::Client::SpanContext.create_parent_context }
  let(:carrier) { {} }

  it 'sets trace information' do
    inject
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
