require 'spec_helper'

RSpec.describe Jaeger::Samplers::Const do
  let(:sampler) { described_class.new(decision) }
  let(:sample_args) { { trace_id: Jaeger::TraceId.generate } }
  let(:sample_result) { sampler.sample(sample_args) }
  let(:is_sampled) { sample_result[0] }
  let(:tags) { sample_result[1] }

  context 'when decision is set to true' do
    let(:decision) { true }

    it 'sets sampling to always true' do
      expect(is_sampled).to eq(true)
    end

    it 'returns tags with param 1' do
      expect(tags).to eq(
        'sampler.type' => 'const',
        'sampler.param' => 1
      )
    end
  end

  context 'when decision is set to false' do
    let(:decision) { false }

    it 'sets sampling to always false' do
      expect(is_sampled).to eq(false)
    end

    it 'returns tags with param 0' do
      expect(tags).to eq(
        'sampler.type' => 'const',
        'sampler.param' => 0
      )
    end
  end
end
