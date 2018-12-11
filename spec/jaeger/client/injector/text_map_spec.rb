require 'spec_helper'

RSpec.describe Jaeger::Client::Injector::TextMap do
  describe '#inject' do
    let(:carrier) { {} }
    let(:expected_trace_id) { '1:3:2:0' }
    let(:span_context) do
      Jaeger::Client::SpanContext.new(
        trace_id: 1,
        parent_id: 2,
        span_id: 3,
        flags: 0x00
      )
    end

    it 'sets trace information' do
      expect { described_class.inject(span_context, carrier) }
        .to change { carrier['uber-trace-id'] }
        .from(nil)
        .to(expected_trace_id)
    end
  end
end
