require 'spec_helper'

RSpec.describe Jaeger::Samplers::RemoteControlled do
  let(:sampler) do
    described_class.new(
      logger: logger,
      poll_executor: poll_executor,
      instructions_fetcher: instructions_fetcher
    )
  end
  let(:logger) { Logger.new('/dev/null') }
  let(:poll_executor) { {} }
  let(:instructions_fetcher) { instance_spy(described_class::InstructionsFetcher) }

  let(:trace_id) { Jaeger::TraceId.generate }
  let(:operation_name) { 'operation-name' }
  let(:sample_args) { { trace_id: trace_id, operation_name: operation_name } }
  let(:parsed_response) { nil }

  before do
    allow(instructions_fetcher).to receive(:fetch).and_return(parsed_response)
  end

  context 'when agent returns probabilistic strategy' do
    let(:rate) { 0.6 }
    let(:parsed_response) do
      {
        'strategyType' => 'PROBABILISTIC',
        'probabilisticSampling' => { 'samplingRate' => rate }
      }
    end

    it 'sets sampler to probabilistic sampler' do
      sampler.poll
      expect(underlying_sampler).to be_a(Jaeger::Samplers::Probabilistic)
      expect(underlying_sampler.rate).to eq(rate)
    end
  end

  context 'when agent returns rate limiting strategy' do
    let(:max_traces_per_second) { 6 }

    let(:parsed_response) do
      {
        'strategyType' => 'RATE_LIMITING',
        'rateLimitingSampling' => { 'maxTracesPerSecond' => max_traces_per_second }
      }
    end

    it 'sets sampler to ratelimiting sampler' do
      sampler.poll
      expect(underlying_sampler).to be_a(Jaeger::Samplers::RateLimiting)
      expect(underlying_sampler.max_traces_per_second).to eq(max_traces_per_second)
    end
  end

  context 'when agent returns per operation strategy' do
    let(:default_sampling_rate) { 0.002 }
    let(:op_sampling_rate) { 0.003 }
    let(:default_traces_per_second) { 2 }

    let(:parsed_response) do
      {
        'strategyType' => 'PROBABILISTIC',
        'operationSampling' => {
          'defaultSamplingProbability' => default_sampling_rate,
          'defaultLowerBoundTracesPerSecond' => default_traces_per_second,
          'perOperationStrategies' => [
            {
              'operation' => operation_name,
              'probabilisticSampling' => {
                'samplingRate' => op_sampling_rate
              }
            }
          ]
        }
      }
    end

    it 'sets sampler to per operation sampler' do
      sampler.poll
      expect(underlying_sampler).to be_a(Jaeger::Samplers::PerOperation)
      expect(underlying_sampler.default_sampling_probability).to eq(default_sampling_rate)
      expect(underlying_sampler.lower_bound).to eq(default_traces_per_second)

      op_sampler = underlying_sampler.samplers[operation_name]
      expect(op_sampler).to be_a(Jaeger::Samplers::GuaranteedThroughputProbabilistic)
      expect(op_sampler.probabilistic_sampler.rate).to eq(op_sampling_rate)
      expect(op_sampler.lower_bound_sampler.max_traces_per_second).to eq(default_traces_per_second)
    end
  end

  context 'when agent returns unknown strategy' do
    let(:parsed_response) do
      { 'strategyType' => 'UH_WHAT_IS_THIS' }
    end

    it 'keeps the current strategy' do
      previous_sampler = underlying_sampler
      sampler.poll
      expect(underlying_sampler).to be(previous_sampler)
    end
  end

  context 'when fetching strategies fails' do
    before do
      allow(instructions_fetcher).to receive(:fetch) do
        raise Jaeger::Samplers::RemoteControlled::InstructionsFetcher::FetchFailed, 'ouch'
      end
    end

    it 'keeps the current strategy' do
      previous_sampler = underlying_sampler
      sampler.poll
      expect(underlying_sampler).to be(previous_sampler)
    end
  end

  def underlying_sampler
    sampler.sampler
  end
end
