# frozen_string_literal: true

module Jaeger
  module Samplers
    # Probabilistic sampler
    #
    # Sample a portion of traces using trace_id as the random decision
    class Probabilistic
      attr_reader :rate

      def initialize(rate: 0.001)
        update(rate: rate)
      end

      def update(rate:)
        if rate < 0.0 || rate > 1.0
          raise "Sampling rate must be between 0.0 and 1.0, got #{rate.inspect}"
        end

        new_boundary = TraceId::TRACE_ID_UPPER_BOUND * rate
        return false if @boundary == new_boundary

        @rate = rate
        @boundary = TraceId::TRACE_ID_UPPER_BOUND * rate
        @tags = {
          'sampler.type' => 'probabilistic',
          'sampler.param' => rate
        }

        true
      end

      def sample(trace_id:, **)
        [@boundary >= trace_id, @tags]
      end
    end
  end
end
