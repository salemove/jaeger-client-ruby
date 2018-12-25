# frozen_string_literal: true

module Jaeger
  module Extractors
    class SerializedJaegerTrace
      def self.parse(trace)
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

    class JaegerTextMapCodec
      def self.extract(carrier)
        context = SerializedJaegerTrace.parse(carrier['uber-trace-id'])
        return nil unless context

        carrier.each do |key, value|
          baggage_match = key.match(/\Auberctx-([\w-]+)\Z/)
          if baggage_match
            context.set_baggage_item(baggage_match[1], value)
          end
        end

        context
      end
    end

    class JaegerRackCodec
      def self.extract(carrier)
        serialized_trace = carrier['HTTP_UBER_TRACE_ID']
        serialized_trace = CGI.unescape(serialized_trace) if serialized_trace
        context = SerializedJaegerTrace.parse(serialized_trace)
        return nil unless context

        carrier.each do |key, value|
          baggage_match = key.match(/\AHTTP_UBERCTX_(\w+)\Z/)
          if baggage_match
            key = baggage_match[1].downcase.tr('_', '-')
            context.set_baggage_item(key, CGI.unescape(value))
          end
        end

        context
      end
    end

    class JaegerBinaryCodec
      def self.extract(_carrier)
        warn 'Jaeger::Client with binary format is not supported yet'
      end
    end

    class B3RackCodec
      def self.extract(carrier)
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
          Jaeger::SpanContext::Flags::DEBUG
        else
          TraceId.base16_hex_id_to_uint64(sampled_header)
        end
      end
      private_class_method :parse_flags
    end

    DEFAULT_EXTRACTORS = {
      OpenTracing::FORMAT_TEXT_MAP => JaegerTextMapCodec,
      OpenTracing::FORMAT_BINARY => JaegerBinaryCodec,
      OpenTracing::FORMAT_RACK => JaegerRackCodec
    }.freeze

    def self.prepare(extractors)
      DEFAULT_EXTRACTORS.reduce(extractors) do |acc, (format, default)|
        provided_extractors = Array(extractors[format])
        provided_extractors += [default] if provided_extractors.empty?

        acc.merge(format => provided_extractors)
      end
    end
  end
end
