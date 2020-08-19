# frozen_string_literal: true

module Jaeger
  module Extractors
    class SerializedJaegerTrace
      def self.parse(trace)
        return nil if !trace || trace == ''

        trace_arguments = trace.split(':')
        return nil if trace_arguments.size != 4

        trace_id = TraceId.base16_hex_id_to_uint128(trace_arguments[0])
        span_id, parent_id, flags = trace_arguments[1..3].map(&TraceId.method(:base16_hex_id_to_uint64))

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
      class Keys
        TRACE_ID = 'HTTP_X_B3_TRACEID'.freeze
        SPAN_ID = 'HTTP_X_B3_SPANID'.freeze
        PARENT_SPAN_ID = 'HTTP_X_B3_PARENTSPANID'.freeze
        FLAGS = 'HTTP_X_B3_FLAGS'.freeze
        SAMPLED = 'HTTP_X_B3_SAMPLED'.freeze
      end.freeze

      def self.extract(carrier)
        B3CodecCommon.extract(carrier, Keys)
      end
    end

    class B3TextMapCodec
      class Keys
        TRACE_ID = 'x-b3-traceid'.freeze
        SPAN_ID = 'x-b3-spanid'.freeze
        PARENT_SPAN_ID = 'x-b3-parentspanid'.freeze
        FLAGS = 'x-b3-flags'.freeze
        SAMPLED = 'x-b3-sampled'.freeze
      end.freeze

      def self.extract(carrier)
        B3CodecCommon.extract(carrier, Keys)
      end
    end

    class B3CodecCommon
      def self.extract(carrier, keys)
        return nil if carrier[keys::TRACE_ID].nil? || carrier[keys::SPAN_ID].nil?

        trace_id = if carrier[keys::TRACE_ID].length <= 16
                     TraceId.base16_hex_id_to_uint64(carrier[keys::TRACE_ID])
                   else
                     TraceId.base16_hex_id_to_uint128(carrier[keys::TRACE_ID])
                   end

        span_id = TraceId.base16_hex_id_to_uint64(carrier[keys::SPAN_ID])
        parent_id = TraceId.base16_hex_id_to_uint64(carrier[keys::PARENT_SPAN_ID])
        flags = parse_flags(carrier[keys::FLAGS], carrier[keys::SAMPLED])

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

    class TraceContextRackCodec
      # Internal regex used to identify the TraceContext version
      VERSION_PATTERN = /^([0-9a-fA-F]{2})-(.+)$/

      # Internal regex used to parse fields in version 0
      HEADER_V0_PATTERN = /^([0-9a-fA-F]{32})-([0-9a-fA-F]{16})(-([0-9a-fA-F]{2}))?$/

      def self.extract(carrier)
        header_value = carrier['HTTP_TRACEPARENT']

        version_match = VERSION_PATTERN.match(header_value)
        return nil unless version_match

        # We currently only support version 0
        return nil if version_match[1].to_i(16) != 0

        match = HEADER_V0_PATTERN.match(version_match[2])
        return nil unless match

        trace_id = TraceId.base16_hex_id_to_uint128(match[1])
        span_id = TraceId.base16_hex_id_to_uint64(match[2])
        flags = TraceId.base16_hex_id_to_uint64(match[4])
        return nil if trace_id.zero? || span_id.zero?

        SpanContext.new(trace_id: trace_id, span_id: span_id, flags: flags)
      end
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
