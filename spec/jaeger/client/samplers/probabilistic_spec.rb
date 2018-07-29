require 'spec_helper'

RSpec.describe Jaeger::Client::Samplers::Probabilistic do
  let(:sampler) { described_class.new(rate: rate) }

  context 'when rate is set to 0' do
    let(:rate) { 0 }

    it 'returns false for every trace' do
      trace_id = Jaeger::Client::TraceId.generate
      expect(sampler.sample?(trace_id)).to eq(false)
    end
  end

  context 'when rate is set to 0.5' do
    let(:rate) { 0.5 }

    it 'returns false for traces over the boundary' do
      trace_id = (0.51 * (2**64 - 1)).to_i
      expect(sampler.sample?(trace_id)).to eq(false)
    end

    it 'returns true for traces under the boundary' do
      trace_id = (0.49 * (2**64 - 1)).to_i
      expect(sampler.sample?(trace_id)).to eq(true)
    end
  end

  context 'when rate is set to 1' do
    let(:rate) { 1 }

    it 'returns true for every trace' do
      trace_id = Jaeger::Client::TraceId.generate
      expect(sampler.sample?(trace_id)).to eq(true)
    end
  end
end
