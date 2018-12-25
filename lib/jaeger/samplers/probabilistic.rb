# frozen_string_literal: true

module Jaeger
  module Samplers
    # Probabilistic sampler
    #
    # Sample a portion of traces using trace_id as the random decision
    class Probabilistic
      def initialize(rate: 0.001)
        if rate < 0.0 || rate > 1.0
          raise "Sampling rate must be between 0.0 and 1.0, got #{rate.inspect}"
        end

        @boundary = TraceId::TRACE_ID_UPPER_BOUND * rate
        @tags = {
          'sampler.type' => 'probabilistic',
          'sampler.param' => rate
        }
      end

      def sample?(trace_id:, **)
        [@boundary >= trace_id, @tags]
      end
    end
  end
end
