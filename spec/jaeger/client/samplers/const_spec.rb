require 'spec_helper'

RSpec.describe Jaeger::Client::Samplers::Const do
  let(:sampler) { described_class.new(decision) }

  context 'when decision is set to true' do
    let(:decision) { true }

    it 'returns true' do
      trace_id = Jaeger::Client::TraceId.generate
      expect(sampler.sample?(trace_id)).to eq(true)
    end
  end

  context 'when decision is set to false' do
    let(:decision) { false }

    it 'returns false' do
      trace_id = Jaeger::Client::TraceId.generate
      expect(sampler.sample?(trace_id)).to eq(false)
    end
  end

  describe '#tags' do
    context 'when decision is true' do
      let(:decision) { true }

      it 'returns tags' do
        expect(sampler.tags).to eq(
          'sampler.type' => 'const',
          'sampler.param' => 1
        )
      end
    end

    context 'when decision is false' do
      let(:decision) { false }

      it 'returns tags' do
        expect(sampler.tags).to eq(
          'sampler.type' => 'const',
          'sampler.param' => 0
        )
      end
    end
  end
end
