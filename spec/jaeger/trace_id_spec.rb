require 'spec_helper'

describe Jaeger::TraceId do
  describe '.base16_hex_id_to_uint64' do
    it 'returns 0 when negative number' do
      id = described_class.base16_hex_id_to_uint64('-1')
      expect(id).to eq(0)
    end

    it 'returns 0 when larger than 64 bit uint' do
      id = described_class.base16_hex_id_to_uint64('10000000000000000')
      expect(id).to eq(0)
    end

    it 'converts base16 encoded hex to uint64' do
      id = described_class.base16_hex_id_to_uint64('ff' * 8)
      expect(id).to eq(2**64 - 1)
    end
  end

  describe '.uint64_id_to_int64' do
    it 'converts large IDs to negative longs' do
      id = described_class.uint64_id_to_int64(2**64 - 1)
      expect(id).to eq(-1)
    end

    it 'converts non large IDs to positive longs' do
      id = described_class.uint64_id_to_int64(2**63 - 1)
      expect(id).to eq(2**63 - 1)
    end
  end
end
