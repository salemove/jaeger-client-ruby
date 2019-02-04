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
      def self.inject(span_context, carrier)
        carrier.clear
        carrier << [0, span_context.trace_id, span_context.span_id, span_context.parent_id, span_context.flags].pack("Q>Q>Q>Q>C")
        span_context.baggage.each do |key, value|
          carrier << [key.bytesize].pack("L>")
          carrier << key
          carrier << [value.bytesize].pack("L>")
          carrier << value
        end
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

    def self.prepare(injectors)
      DEFAULT_INJECTORS.reduce(injectors) do |acc, (format, default)|
        provided_injectors = Array(injectors[format])
        provided_injectors += [default] if provided_injectors.empty?

        acc.merge(format => provided_injectors)
      end
    end
  end
end
