# frozen_string_literal: true

module Jaeger
  module Client
    module PropagationCodec
      class JaegerCodec

        # Inject a SpanContext into the given carrier
        #
        # @param span_context [SpanContext]
        # @param carrier [carrier] A carrier object of type TEXT_MAP or RACK
        def inject(span_context, carrier)
          carrier['uber-trace-id'] = [
            span_context.trace_id.to_s(16),
            span_context.span_id.to_s(16),
            span_context.parent_id.to_s(16),
            span_context.flags.to_s(16)
          ].join(':')
        end

        # Extract a SpanContext from a given carrier in the Text Map format
        #
        # @param carrier [Carrier] A carrier of type Text Map
        # @return [SpanContext] the extracted SpanContext or nil if none was extracted
        def extract_text_map(carrier)
          parse_context(carrier['uber-trace-id'])
        end

        # Extract a SpanContext from a given carrier in the Rack format
        #
        # @param carrier [Carrier] A carrier of type Rack
        # @return [SpanContext] the extracted SpanContext or nil if none was extracted
        def extract_rack(carrier)
          parse_context(carrier['HTTP_UBER_TRACE_ID'])
        end

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
