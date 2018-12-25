require 'spec_helper'

RSpec.describe Jaeger::Client::Samplers::PerOperation do
  let(:sampler) { described_class.new(strategies: strategies, max_operations: max_operations) }
  let(:max_operations) { 1000 }

  # let(:sample_args) { { trace_id: trace_id } }
  # let(:sample_result) { sampler.sample?(sample_args) }
  # let(:is_sampled) { sample_result[0] }
  # let(:tags) { sample_result[1] }
  let(:start_time) { Time.now }

  before { Timecop.freeze(start_time) }

  after { Timecop.return }

  context 'when operation strategy is defined' do
    context 'when operation rate is set to 0' do
      let(:strategies) do
        {
          default_sampling_probability: 1.0,
          default_lower_bound_traces_per_second: 1,
          per_operation_strategies: [
            { operation: 'foo', probabilistic_sampling: 0 }
          ]
        }
      end

      it 'uses lower bound sampler' do
        is_sampled, _tags = sampler.sample?(sample_args(operation_name: 'foo'))
        expect(is_sampled).to eq(true)

        # false because limit is full
        is_sampled, _tags = sampler.sample?(sample_args(operation_name: 'foo'))
        expect(is_sampled).to eq(false)

        # true because different operation
        is_sampled, _tags = sampler.sample?(sample_args(operation_name: 'bar'))
        expect(is_sampled).to eq(true)
      end

      it 'returns tags with lower bound param' do
        _is_sampled, tags = sampler.sample?(sample_args(operation_name: 'foo'))
        expect(tags).to eq(
          'sampler.type' => 'lowerbound',
          'sampler.param' => 1
        )
      end
    end

    context 'when operation rate is set to 1' do
      let(:strategies) do
        {
          default_sampling_probability: 0,
          default_lower_bound_traces_per_second: 1,
          per_operation_strategies: [
            { operation: 'foo', probabilistic_sampling: 1.0 }
          ]
        }
      end

      it 'uses operation probabilistic sampler' do
        is_sampled, _tags = sampler.sample?(sample_args(operation_name: 'foo'))
        expect(is_sampled).to eq(true)

        # true because rate is set to 1
        is_sampled, _tags = sampler.sample?(sample_args(operation_name: 'foo'))
        expect(is_sampled).to eq(true)

        is_sampled, _tags = sampler.sample?(sample_args(operation_name: 'bar'))
        expect(is_sampled).to eq(true)

        # false because different operation and lower boundary is full
        is_sampled, _tags = sampler.sample?(sample_args(operation_name: 'bar'))
        expect(is_sampled).to eq(false)
      end

      it 'returns tags with lower bound param' do
        _is_sampled, tags = sampler.sample?(sample_args(operation_name: 'foo'))
        expect(tags).to eq(
          'sampler.type' => 'probabilistic',
          'sampler.param' => 1.0
        )
      end
    end
  end

  context 'when operation strategy is undefined' do
    context 'when default rate is set to 0' do
      let(:strategies) do
        {
          default_sampling_probability: 0,
          default_lower_bound_traces_per_second: 1
        }
      end

      it 'uses lower bound sampler' do
        is_sampled, _tags = sampler.sample?(sample_args(operation_name: 'foo'))
        expect(is_sampled).to eq(true)

        # false because limit is full
        is_sampled, _tags = sampler.sample?(sample_args(operation_name: 'foo'))
        expect(is_sampled).to eq(false)

        # true because different operation
        is_sampled, _tags = sampler.sample?(sample_args(operation_name: 'bar'))
        expect(is_sampled).to eq(true)
      end

      it 'returns tags with lower bound param' do
        _is_sampled, tags = sampler.sample?(sample_args(operation_name: 'foo'))
        expect(tags).to eq(
          'sampler.type' => 'lowerbound',
          'sampler.param' => 1
        )
      end
    end

    context 'when default rate is set to 1' do
      let(:strategies) do
        {
          default_sampling_probability: 1,
          default_lower_bound_traces_per_second: 1
        }
      end

      it 'uses probabilistic sampling which returns always true' do
        is_sampled, _tags = sampler.sample?(sample_args(operation_name: 'foo'))
        expect(is_sampled).to eq(true)

        is_sampled, _tags = sampler.sample?(sample_args(operation_name: 'foo'))
        expect(is_sampled).to eq(true)
      end

      it 'returns tags with lower bound param' do
        _is_sampled, tags = sampler.sample?(sample_args(operation_name: 'foo'))
        expect(tags).to eq(
          'sampler.type' => 'probabilistic',
          'sampler.param' => 1
        )
      end
    end
  end

  def sample_args(opts = {})
    {
      trace_id: Jaeger::Client::TraceId.generate,
      operation_name: 'operation-name'
    }.merge(opts)
  end
end
