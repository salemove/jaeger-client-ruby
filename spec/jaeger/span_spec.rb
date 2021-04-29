require 'spec_helper'

RSpec.describe Jaeger::Span do
  describe '#log' do
    let(:span) { described_class.new(nil, 'operation_name', nil) }

    it 'is deprecated' do
      expect { span.log(key: 'value') }
        .to output(/Span#log is deprecated/).to_stderr
    end

    it 'delegates to #log_kv' do
      allow(span).to receive(:log_kv)

      args = { key: 'value' }
      span.log(**args)

      expect(span).to have_received(:log_kv).with(**args)
    end
  end

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
      span.log_kv(**fields)

      expect(span.logs.count).to eq(1)
      thrift_log = span.logs[0]
      expect(thrift_log.timestamp).to be_a(Integer)
      expect(thrift_log.fields).to match(expected_thrift_fields)
    end

    it 'adds log to span with specific timestamp' do
      timestamp = Time.now
      span.log_kv(**fields.merge(timestamp: timestamp))

      expect(span.logs.count).to eq(1)
      thrift_log = span.logs[0]
      expect(thrift_log.timestamp).to eq((timestamp.to_f * 1_000_000).to_i)
      expect(thrift_log.fields).to match(expected_thrift_fields)
    end
  end

  it 'stores and retrieves baggage' do
    span_context = build_span_context
    span = described_class.new(span_context, 'operation_name', nil)

    span.set_baggage_item('foo', 'bar')
    expect(span.get_baggage_item('foo')).to eq('bar')

    span.set_baggage_item('foo', 'baz')
    expect(span.get_baggage_item('foo')).to eq('baz')
  end

  describe '#set_tag' do
    let(:span_context) { build_span_context }
    let(:span) { described_class.new(span_context, 'operation_name', nil) }

    context 'when sampling.priority' do
      it 'sets debug flag to true when sampling.priority is greater than 0' do
        span.set_tag('sampling.priority', 1)
        expect(span.context.debug?).to eq(true)
        expect(span.context.sampled?).to eq(true)
      end

      it 'sets sampled flag to false when sampling.priority is 0' do
        span.set_tag('sampling.priority', 0)
        expect(span.context.debug?).to eq(false)
        expect(span.context.sampled?).to eq(false)
      end
    end
  end
end
