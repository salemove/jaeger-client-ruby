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

      attr_reader :default_sampling_probability, :lower_bound, :samplers

      def initialize(strategies:, max_operations:)
        @max_operations = max_operations
        @samplers = {}
        update(strategies: strategies)
      end

      def update(strategies:)
        is_updated = false

        @default_sampling_probability =
          strategies[:default_sampling_probability] || DEFAULT_SAMPLING_PROBABILITY
        @lower_bound =
          strategies[:default_lower_bound_traces_per_second] || DEFAULT_LOWER_BOUND

        if @default_sampler
          is_updated = @default_sampler.update(rate: @default_sampling_probability)
        else
          @default_sampler = Probabilistic.new(rate: @default_sampling_probability)
        end

        is_updated = update_operation_strategies(strategies) || is_updated

        is_updated
      end

      def sample(opts)
        operation_name = opts.fetch(:operation_name)
        sampler = @samplers[operation_name]
        return sampler.sample(opts) if sampler

        return @default_sampler.sample(opts) if @samplers.length >= @max_operations

        sampler = GuaranteedThroughputProbabilistic.new(
          lower_bound: @lower_bound,
          rate: @default_sampling_probability
        )
        @samplers[operation_name] = sampler
        sampler.sample(opts)
      end

      private

      def update_operation_strategies(strategies)
        is_updated = false

        (strategies[:per_operation_strategies] || []).each do |strategy|
          operation = strategy.fetch(:operation)
          rate = strategy.fetch(:probabilistic_sampling).fetch(:sampling_rate)

          if (sampler = @samplers[operation])
            is_updated = sampler.update(lower_bound: @lower_bound, rate: rate) || is_updated
          else
            @samplers[operation] = GuaranteedThroughputProbabilistic.new(
              lower_bound: @lower_bound,
              rate: rate
            )
            is_updated = true
          end
        end

        is_updated
      end
    end
  end
end
