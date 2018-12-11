# frozen_string_literal: true

module Jaeger
  module Client
    module PropagationCodec
      module B3Codec
        # Inject a SpanContext into the given carrier
        #
        # @param span_context [SpanContext]
        # @param carrier [carrier] A carrier object of type TEXT_MAP or RACK
        def self.inject(span_context, format, carrier)
          case format
          when OpenTracing::FORMAT_TEXT_MAP, OpenTracing::FORMAT_RACK
            carrier['x-b3-traceid'] = TraceId.to_hex(span_context.trace_id)
            carrier['x-b3-spanid'] = TraceId.to_hex(span_context.span_id)
            carrier['x-b3-parentspanid'] = TraceId.to_hex(span_context.parent_id)

            # flags (for debug) and sampled headers are mutually exclusive
            if span_context.flags == Jaeger::Client::SpanContext::Flags::DEBUG
              carrier['x-b3-flags'] = '1'
            else
              carrier['x-b3-sampled'] = span_context.flags.to_s(16)
            end
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
            extract_text_map(carrier)
          when OpenTracing::FORMAT_RACK
            extract_rack(carrier)
          else
            warn "Jaeger::Client with format #{format} is not supported yet"
            nil
          end
        end

        # Extract a SpanContext from a given carrier in the Text Map format
        #
        # @param carrier [Carrier] A carrier of type Text Map
        # @return [SpanContext] the extracted SpanContext or nil if none was extracted
        def self.extract_text_map(carrier)
          trace_id = TraceId.base16_hex_id_to_uint64(carrier['x-b3-traceid'])
          span_id = TraceId.base16_hex_id_to_uint64(carrier['x-b3-spanid'])
          parent_id = TraceId.base16_hex_id_to_uint64(carrier['x-b3-parentspanid'])
          flags = parse_flags(carrier['x-b3-flags'], carrier['x-b3-sampled'])

          return nil if span_id.nil? || trace_id.nil?
          return nil if span_id.zero? || trace_id.zero?

          SpanContext.new(
            trace_id: trace_id,
            parent_id: parent_id,
            span_id: span_id,
            flags: flags
          )
        end

        # Extract a SpanContext from a given carrier in the Rack format
        #
        # @param carrier [Carrier] A carrier of type Rack
        # @return [SpanContext] the extracted SpanContext or nil if none was extracted
        def self.extract_rack(carrier)
          trace_id = TraceId.base16_hex_id_to_uint64(carrier['HTTP_X_B3_TRACEID'])
          span_id = TraceId.base16_hex_id_to_uint64(carrier['HTTP_X_B3_SPANID'])
          parent_id = TraceId.base16_hex_id_to_uint64(carrier['HTTP_X_B3_PARENTSPANID'])
          flags = parse_flags(carrier['HTTP_X_B3_FLAGS'], carrier['HTTP_X_B3_SAMPLED'])

          return nil if span_id.nil? || trace_id.nil?
          return nil if span_id.zero? || trace_id.zero?

          SpanContext.new(
            trace_id: trace_id,
            parent_id: parent_id,
            span_id: span_id,
            flags: flags
          )
        end

        # if the flags header is '1' then the sampled header should not be present
        def self.parse_flags(flags_header, sampled_header)
          if flags_header == '1'
            Jaeger::Client::SpanContext::Flags::DEBUG
          else
            TraceId.base16_hex_id_to_uint64(sampled_header)
          end
        end
      end
    end
  end
end
