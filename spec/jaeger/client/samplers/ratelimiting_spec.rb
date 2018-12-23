require 'spec_helper'

RSpec.describe Jaeger::Client::Samplers::Ratelimiting do
  let(:sampler) { described_class.new(max_traces_per_second: max_traces_per_second) }
  let(:max_traces_per_second) { 10 }
  let(:sample_args) { { trace_id: Jaeger::Client::TraceId.generate } }
  let(:sample_result) { sampler.sample?(sample_args) }
  let(:is_sampled) { sample_result[0] }
  let(:tags) { sample_result[1] }

  context 'when max_traces_per_second is negative' do
    let(:max_traces_per_second) { -1 }

    it 'throws an error' do
      expect { sampler }.to raise_error(
        "max_traces_per_second must not be negative, got #{max_traces_per_second}"
      )
    end
  end

  describe '#sample?' do
    it 'returns a boolean' do
      expect(is_sampled).to be(true).or be(false)
    end

    it 'returns tags' do
      expect(tags).to eq(
        'sampler.type' => 'ratelimiting',
        'sampler.param' => max_traces_per_second
      )
    end
  end
end
