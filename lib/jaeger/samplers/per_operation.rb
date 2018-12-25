# frozen_string_literal: true

module Jaeger
  module Samplers
    # A sampler that leverages both Probabilistic sampler and RateLimiting
    # sampler via the GuaranteedThroughputProbabilistic sampler. This sampler
    # keeps track of all operations and delegates calls the the respective
    # GuaranteedThroughputProbabilistic sampler.
    class PerOperation
      DEFAULT_SAMPLING_PROBABILITY = 0.001
      DEFAULT_LOWER_BOUND = 1.0 / (10.0 * 60.0) # sample once every 10 minutes'

      def initialize(strategies:, max_operations:)
        @max_operations = max_operations
        @default_sampling_probability =
          strategies[:default_sampling_probability] || DEFAULT_SAMPLING_PROBABILITY
        @lower_bound = strategies[:default_lower_bound_traces_per_second] || DEFAULT_LOWER_BOUND

        @default_sampler = Probabilistic.new(rate: @default_sampling_probability)
        @samplers = (strategies[:per_operation_strategies] || []).reduce({}) do |acc, strategy|
          operation = strategy.fetch(:operation)
          rate = strategy.fetch(:probabilistic_sampling)
          sampler = GuaranteedThroughputProbabilistic.new(
            lower_bound: @lower_bound,
            rate: rate
          )
          acc.merge(operation => sampler)
        end
      end

      def sample?(opts)
        operation_name = opts.fetch(:operation_name)
        sampler = @samplers[operation_name]
        return sampler.sample?(opts) if sampler

        return @default_sampler.sample?(opts) if @samplers.length >= @max_operations

        sampler = GuaranteedThroughputProbabilistic.new(
          lower_bound: @lower_bound,
          rate: @default_sampling_probability
        )
        @samplers[operation_name] = sampler
        sampler.sample?(opts)
      end
    end
  end
end
