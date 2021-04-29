require 'spec_helper'

RSpec.describe Jaeger::Samplers::GuaranteedThroughputProbabilistic do
  let(:sampler) do
    described_class.new(
      lower_bound: lower_bound,
      rate: rate,
      lower_bound_sampler: lower_bound_sampler
    )
  end
  let(:lower_bound) { 5 }
  let(:rate) { 0.5 }
  let(:lower_bound_sampler) { instance_double(Jaeger::Samplers::RateLimiting) }

  let(:max_traces_per_second) { 10 }
  let(:sample_args) { { trace_id: trace_id } }
  let(:sample_result) { sampler.sample(**sample_args) }
  let(:is_sampled) { sample_result[0] }
  let(:tags) { sample_result[1] }

  context 'when rate is set to 0' do
    let(:rate) { 0 }
    let(:trace_id) { Jaeger::TraceId.generate }

    context 'when lower bound return false' do
      before do
        allow(lower_bound_sampler).to receive(:sample)
          .and_return([false, {}])
      end

      it 'returns false for every trace' do
        expect(is_sampled).to eq(false)
      end

      it 'returns tags with param 0' do
        expect(tags).to eq(
          'sampler.type' => 'lowerbound',
          'sampler.param' => rate
        )
      end
    end

    context 'when lower bound sampler returns true' do
      before do
        allow(lower_bound_sampler).to receive(:sample)
          .and_return([true, {}])
      end

      it 'returns true' do
        expect(is_sampled).to eq(true)
      end

      it 'returns tags with lower bound param' do
        expect(tags).to eq(
          'sampler.type' => 'lowerbound',
          'sampler.param' => rate
        )
      end
    end
  end

  context 'when rate is set to 1' do
    let(:rate) { 1 }
    let(:trace_id) { Jaeger::TraceId.generate }

    before do
      allow(lower_bound_sampler).to receive(:sample)
    end

    it 'returns true for every trace' do
      expect(is_sampled).to eq(true)
    end

    it 'returns tags with param 1' do
      expect(tags).to eq(
        'sampler.type' => 'probabilistic',
        'sampler.param' => rate
      )
    end

    it 'calls lower bound sampler' do
      expect(lower_bound_sampler).to receive(:sample).with(sample_args)
      is_sampled
    end
  end
end
