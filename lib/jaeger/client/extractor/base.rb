# frozen_string_literal: true

module Jaeger
  module Client
    class Extractor
      class Base
        class << self
          private

          def parse_context(trace)
            return nil if !trace || trace == ''

            trace_arguments = trace.split(':').map(&TraceId.method(:base16_hex_id_to_uint64))
            return nil if trace_arguments.size != 4

            trace_id, span_id, parent_id, flags = trace_arguments
            return nil if trace_id.zero? || span_id.zero?

            SpanContext.new(
              trace_id: trace_id,
              parent_id: parent_id,
              span_id: span_id,
              flags: flags
            )
          end
        end
      end
    end
  end
end
