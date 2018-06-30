require 'spec_helper'

RSpec.describe Jaeger::Client::Span do
  describe '#log_kv' do
    let(:span) { described_class.new(nil, 'operation_name', nil) }
    let(:fields) { { key1: 'value1', key2: 'value2' } }

    it 'returns nil' do
      expect(span.log_kv(key: 'value')).to be_nil
    end

    it 'adds log to span' do
      log = { key1: 'value1', key2: 'value2' }
      span.log_kv(log)

      expect(span.logs.count).to eq(1)
      expect(span.logs[0]).to include(
        timestamp: instance_of(Time), fields: fields
      )
    end

    it 'adds log to span with specific timestamp' do
      timestamp = Time.now
      span.log_kv(fields.merge(timestamp: timestamp))

      expect(span.logs.count).to eq(1)
      expect(span.logs[0]).to eq(timestamp: timestamp, fields: fields)
    end
  end
end
