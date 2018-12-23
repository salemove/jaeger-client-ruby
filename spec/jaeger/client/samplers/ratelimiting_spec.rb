require 'spec_helper'

RSpec.describe Jaeger::Client::Samplers::Ratelimiting do
  let(:sampler) { described_class.new(max_traces_per_second: max_traces_per_second) }
  let(:max_traces_per_second) { 10 }

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
      expect(sampler.sample?).to be(true).or be(false)
    end
  end

  describe '#type' do
    it 'returns ratelimiting' do
      expect(sampler.type).to eq('ratelimiting')
    end
  end
end
