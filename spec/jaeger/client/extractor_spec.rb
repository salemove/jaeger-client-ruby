require 'spec_helper'

RSpec.describe Jaeger::Client::Extractor do
  describe '::register' do
    let(:extractor) { Class.new }
    let(:format) { 'FOO' }

    it 'registers new extractor with given format' do
      expect { described_class.register(format, extractor) }
        .to change { described_class.extractors[format] }
        .from(nil).to(extractor)
    end
  end

  describe '::extract' do
    context 'when there is an extractor for given format' do
      let(:extractor) { spy }
      let(:format) { 'BAR' }
      let(:carrier) { {} }

      before do
        described_class.register(format, extractor)
      end

      it 'delegates the call to extractor of format' do
        described_class.extract(format, carrier)

        expect(extractor).to have_received(:extract).with(carrier).once
      end
    end

    context 'when there is no extractor for given format' do
      before { allow(described_class).to receive(:warn) }

      it 'puts a warning message' do
        described_class.extract('UNKNOWN_FORMAT', {})

        expect(described_class).to have_received(:warn)
      end
    end
  end
end
