require 'spec_helper'

RSpec.describe Jaeger::Client::Span do
  describe '#log_kv' do
    let(:span) { described_class.new(nil, 'operation_name', nil) }
    let(:fields) { { key1: 'value1', key2: 69 } }
    let(:expected_thrift_fields) do
      [
        Jaeger::Thrift::Tag.new(key: 'key1', vType: 0, vStr: 'value1'),
        Jaeger::Thrift::Tag.new(key: 'key2', vType: 3, vLong: 69)
      ]
    end

    it 'returns nil' do
      expect(span.log_kv(key: 'value')).to be_nil
    end

    it 'adds log to span' do
      span.log_kv(fields)

      expect(span.logs.count).to eq(1)
      thrift_log = span.logs[0]
      expect(thrift_log.timestamp).to be_a(Integer)
      expect(thrift_log.fields).to match(expected_thrift_fields)
    end

    it 'adds log to span with specific timestamp' do
      timestamp = Time.now
      span.log_kv(fields.merge(timestamp: timestamp))

      expect(span.logs.count).to eq(1)
      thrift_log = span.logs[0]
      expect(thrift_log.timestamp).to eq(timestamp.to_f * 1_000_000)
      expect(thrift_log.fields).to match(expected_thrift_fields)
    end
  end
end
