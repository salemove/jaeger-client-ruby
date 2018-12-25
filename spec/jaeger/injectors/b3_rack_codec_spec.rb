require 'spec_helper'

describe Jaeger::Injectors::B3RackCodec do
  let(:inject) { described_class.inject(span_context, carrier) }

  let(:span_context) { build_span_context }
  let(:carrier) { {} }

  it 'sets trace information' do
    inject
    expect(carrier['x-b3-traceid']).to eq(span_context.trace_id.to_s(16).rjust(16, '0'))
    expect(carrier['x-b3-spanid']).to eq(span_context.span_id.to_s(16).rjust(16, '0'))
    expect(carrier['x-b3-parentspanid']).to eq(span_context.parent_id.to_s(16).rjust(16, '0'))
    expect(carrier['x-b3-sampled']).to eq(span_context.flags.to_s(16))
  end

  context 'when sampler flag is DEBUG' do
    let(:span_context) do
      Jaeger::SpanContext.new(
        span_id: Jaeger::TraceId.generate,
        trace_id: Jaeger::TraceId.generate,
        flags: 0x02
      )
    end

    it 'sets the x-b3-flags header' do
      inject
      expect(carrier).to have_key 'x-b3-flags'
      expect(carrier['x-b3-flags']).to eq '1'
    end

    it 'does not set the x-b3-sampled header' do
      inject
      expect(carrier).not_to have_key 'x-b3-sampled'
    end
  end

  context 'when span context IDs are longer than 16 characters' do
    let(:span_context) do
      Jaeger::SpanContext.new(
        span_id: 0xFFFFFFFFFFFFFFFFF,
        parent_id: 0xFFFFFFFFFFFFFFFFF,
        trace_id: 0xFFFFFFFFFFFFFFFFF,
        flags: 0
      )
    end

    it 'pads the hex id strings to 32 characters' do
      inject
      expect(carrier['x-b3-traceid'].length).to eq 32
      expect(carrier['x-b3-spanid'].length).to eq 32
      expect(carrier['x-b3-parentspanid'].length).to eq 32
    end
  end
end
