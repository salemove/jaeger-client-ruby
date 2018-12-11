require 'spec_helper'

RSpec.describe Jaeger::Client::Injector do
  describe '::register' do
    let(:injector) { Class.new }
    let(:format) { 'FOO' }

    it 'registers new injector with given format' do
      expect { described_class.register(format, injector) }
        .to change { described_class.injectors[format] }
        .from(nil).to(injector)
    end
  end

  describe '::inject' do
    let(:span_context) do
      Jaeger::Client::SpanContext.new(
        trace_id: 'trace-id',
        parent_id: nil,
        span_id: 'span-id',
        flags: 0x00
      )
    end

    context 'when there is an injector for given format' do
      let(:injector) { spy }
      let(:format) { 'BAR' }
      let(:carrier) { {} }

      before do
        described_class.register(format, injector)
      end

      it 'delegates the call to injector of format' do
        described_class.inject(span_context, format, carrier)

        expect(injector).to have_received(:inject).with(span_context, carrier)
      end
    end

    context 'when there is no injector for given format' do
      before { allow(described_class).to receive(:warn) }

      it 'puts a warning message' do
        described_class.inject(span_context, 'UNKNOWN_FORMAT', {})

        expect(described_class).to have_received(:warn)
      end
    end
  end
end
