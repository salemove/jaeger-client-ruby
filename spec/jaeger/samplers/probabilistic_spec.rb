require 'spec_helper'

RSpec.describe Jaeger::Samplers::Probabilistic do
  let(:sampler) { described_class.new(rate: rate) }
  let(:sample_args) { { trace_id: trace_id } }
  let(:sample_result) { sampler.sample(**sample_args) }
  let(:is_sampled) { sample_result[0] }
  let(:tags) { sample_result[1] }

  context 'when rate is set to 0' do
    let(:rate) { 0 }
    let(:trace_id) { Jaeger::TraceId.generate }

    it 'returns false for every trace' do
      expect(is_sampled).to eq(false)
    end

    it 'returns tags with param 0' do
      expect(tags).to eq(
        'sampler.type' => 'probabilistic',
        'sampler.param' => 0
      )
    end
  end

  context 'when rate is set to 0.5' do
    let(:rate) { 0.5 }

    context 'when trace is over the boundary' do
      let(:trace_id) { Jaeger::TraceId::TRACE_ID_UPPER_BOUND / 2 + 1 }

      it 'returns false' do
        expect(is_sampled).to eq(false)
      end

      it 'returns tags with param 0.5' do
        expect(tags).to eq(
          'sampler.type' => 'probabilistic',
          'sampler.param' => 0.5
        )
      end
    end

    context 'when trace is under the boundary' do
      let(:trace_id) { Jaeger::TraceId::TRACE_ID_UPPER_BOUND / 2 - 1 }

      it 'returns true' do
        expect(is_sampled).to eq(true)
      end

      it 'returns tags with param 0.5' do
        expect(tags).to eq(
          'sampler.type' => 'probabilistic',
          'sampler.param' => 0.5
        )
      end
    end
  end

  context 'when rate is set to 1' do
    let(:rate) { 1 }
    let(:trace_id) { Jaeger::TraceId.generate }

    it 'returns true for every trace' do
      expect(is_sampled).to eq(true)
    end

    it 'returns tags with param 1' do
      expect(tags).to eq(
        'sampler.type' => 'probabilistic',
        'sampler.param' => 1
      )
    end
  end
end
