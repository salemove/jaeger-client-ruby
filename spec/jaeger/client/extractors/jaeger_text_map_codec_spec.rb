require 'spec_helper'

describe Jaeger::Client::Extractors::JaegerTextMapCodec do
  let(:span_context) { described_class.extract(carrier) }

  let(:carrier) { { 'uber-trace-id' => "#{trace_id}:#{span_id}:#{parent_id}:#{flags}" } }
  let(:trace_id) { '58a515c97fd61fd7' }
  let(:parent_id) { '8e5a8c5509c8dcc1' }
  let(:span_id) { 'aba8be8d019abed2' }
  let(:flags) { '1' }
  let(:hexa_max_uint64) { 'ff' * 8 }
  let(:max_uint64) { 2**64 - 1 }

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
