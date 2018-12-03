# frozen_string_literal: true

module Jaeger
  module Client
    module PropagationCodec
      module JaegerCodec
        # Inject a SpanContext into the given carrier
        #
        # @param span_context [SpanContext]
        # @param carrier [carrier] A carrier object of type TEXT_MAP or RACK
        def self.inject(span_context, format, carrier)
          case format
          when OpenTracing::FORMAT_TEXT_MAP, OpenTracing::FORMAT_RACK
            carrier['uber-trace-id'] = [
              span_context.trace_id.to_s(16),
              span_context.span_id.to_s(16),
              span_context.parent_id.to_s(16),
              span_context.flags.to_s(16)
            ].join(':')
          else
            warn "Jaeger::Client with format #{format} is not supported yet"
          end
        end

        # Extract a SpanContext in the given format from the given carrier.
        #
        # @param format [OpenTracing::FORMAT_TEXT_MAP, OpenTracing::FORMAT_BINARY, OpenTracing::FORMAT_RACK]
        # @param carrier [Carrier] A carrier object of the type dictated by the specified `format`
        # @return [SpanContext] the extracted SpanContext or nil if none could be found
        def self.extract(format, carrier)
          case format
          when OpenTracing::FORMAT_TEXT_MAP
            parse_context(carrier['uber-trace-id'])
          when OpenTracing::FORMAT_RACK
            parse_context(carrier['HTTP_UBER_TRACE_ID'])
          else
            warn "Jaeger::Client with format #{format} is not supported yet"
            nil
          end
        end

        def self.parse_context(trace)
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
