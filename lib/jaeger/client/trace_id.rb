# frozen_string_literal: true

module Jaeger
  module Client
    module TraceId
      TRACE_ID_UPPER_BOUND = 2**64 - 1

      def self.generate
        rand(TRACE_ID_UPPER_BOUND)
      end
    end
  end
end
