# frozen_string_literal: true

module Jaeger
  module Samplers
    # A sampler that leverages both Probabilistic sampler and RateLimiting
    # sampler. The RateLimiting is used as a guaranteed lower bound sampler
    # such that every operation is sampled at least once in a time interval
    # defined by the lower_bound. ie a lower_bound of 1.0 / (60 * 10) will
    # sample an operation at least once every 10 minutes.
    #
    # The Probabilistic sampler is given higher priority when tags are
    # emitted, ie. if is_sampled() for both samplers return true, the tags
    # for Probabilistic sampler will be used.
    class GuaranteedThroughputProbabilistic
      attr_reader :tags

      def initialize(lower_bound:, rate:, lower_bound_sampler: nil)
        @probabilistic_sampler = Probabilistic.new(rate: rate)
        @lower_bound_sampler = lower_bound_sampler || RateLimiting.new(max_traces_per_second: lower_bound)
        @lower_bound_tags = {
          'sampler.type' => 'lowerbound',
          'sampler.param' => lower_bound
        }
      end

      def sample?(*args)
        is_sampled, probabilistic_tags = @probabilistic_sampler.sample?(*args)
        if is_sampled
          # We still call lower_bound_sampler to update the rate limiter budget
          @lower_bound_sampler.sample?(*args)

          return [is_sampled, probabilistic_tags]
        end

        is_sampled, _tags = @lower_bound_sampler.sample?(*args)
        [is_sampled, @lower_bound_tags]
      end
    end
  end
end
