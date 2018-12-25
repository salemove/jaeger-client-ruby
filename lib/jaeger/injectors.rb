# frozen_string_literal: true

module Jaeger
  module Injectors
    def self.context_as_jaeger_string(span_context)
      [
        span_context.trace_id.to_s(16),
        span_context.span_id.to_s(16),
        span_context.parent_id.to_s(16),
        span_context.flags.to_s(16)
      ].join(':')
    end

    class JaegerTextMapCodec
      def self.inject(span_context, carrier)
        carrier['uber-trace-id'] = Injectors.context_as_jaeger_string(span_context)
        span_context.baggage.each do |key, value|
          carrier["uberctx-#{key}"] = value
        end
      end
    end

    class JaegerRackCodec
      def self.inject(span_context, carrier)
        carrier['uber-trace-id'] =
          CGI.escape(Injectors.context_as_jaeger_string(span_context))
        span_context.baggage.each do |key, value|
          carrier["uberctx-#{key}"] = CGI.escape(value)
        end
      end
    end

    class JaegerBinaryCodec
      def self.inject(_span_context, _carrier)
        warn 'Jaeger::Client with binary format is not supported yet'
      end
    end

    class B3RackCodec
      def self.inject(span_context, carrier)
        carrier['x-b3-traceid'] = TraceId.to_hex(span_context.trace_id)
        carrier['x-b3-spanid'] = TraceId.to_hex(span_context.span_id)
        carrier['x-b3-parentspanid'] = TraceId.to_hex(span_context.parent_id)

        # flags (for debug) and sampled headers are mutually exclusive
        if span_context.flags == Jaeger::SpanContext::Flags::DEBUG
          carrier['x-b3-flags'] = '1'
        else
          carrier['x-b3-sampled'] = span_context.flags.to_s(16)
        end
      end
    end

    DEFAULT_INJECTORS = {
      OpenTracing::FORMAT_TEXT_MAP => JaegerTextMapCodec,
      OpenTracing::FORMAT_BINARY => JaegerBinaryCodec,
      OpenTracing::FORMAT_RACK => JaegerRackCodec
    }.freeze

    def self.prepare(extractors)
      DEFAULT_INJECTORS.reduce(extractors) do |acc, (format, default)|
        provided_extractors = Array(extractors[format])
        provided_extractors += [default] if provided_extractors.empty?

        acc.merge(format => provided_extractors)
      end
    end
  end
end
