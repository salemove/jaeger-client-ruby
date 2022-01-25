require 'spec_helper'

describe Jaeger::Extractors::TraceContextRackCodec do
  it 'parses valid sampled v0 traceparent' do
    carrier = { 'HTTP_TRACEPARENT' => '00-00000000030c22224787fd223b027d8d-000f5cf3018c0a93-01' }
    span_context = described_class.extract(carrier)

    expect(span_context.trace_id).to eq(943_123_332_103_493_452_342_394_253)
    expect(span_context.span_id).to eq(4_324_323_423_423_123)
    expect(span_context.sampled?).to eq(true)
  end

  it 'parses valid non-sampled v0 traceparent' do
    carrier = { 'HTTP_TRACEPARENT' => '00-00000000030c22224787fd223b027d8d-000f5cf3018c0a93-00' }
    span_context = described_class.extract(carrier)

    expect(span_context.trace_id).to eq(943_123_332_103_493_452_342_394_253)
    expect(span_context.span_id).to eq(4_324_323_423_423_123)
    expect(span_context.sampled?).to eq(false)
  end

  it 'parses valid traceparent with largest trace id and span id' do
    carrier = { 'HTTP_TRACEPARENT' => '00-ffffffffffffffffffffffffffffffff-ffffffffffffffff-01' }
    span_context = described_class.extract(carrier)

    expect(span_context.trace_id).to eq((2**128) - 1)
    expect(span_context.span_id).to eq((2**64) - 1)
    expect(span_context.sampled?).to eq(true)
  end

  it 'returns nil when unhandled version' do
    carrier = { 'HTTP_TRACEPARENT' => '01-00000000030c22224787fd223b027d8d-000f5cf3018c0a93-01' }
    span_context = described_class.extract(carrier)

    expect(span_context).to eq(nil)
  end

  it 'returns nil when trace id is 0' do
    carrier = { 'HTTP_TRACEPARENT' => '00-00000000000000000000000000000000-000f5cf3018c0a93-01' }
    span_context = described_class.extract(carrier)

    expect(span_context).to eq(nil)
  end

  it 'returns nil when span id is 0' do
    carrier = { 'HTTP_TRACEPARENT' => '00-00000000030c22224787fd223b027d8d-0000000000000000-01' }
    span_context = described_class.extract(carrier)

    expect(span_context).to eq(nil)
  end
end
