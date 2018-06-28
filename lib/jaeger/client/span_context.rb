module Jaeger
  module Client
    # SpanContext holds the data for a span that gets inherited to child spans
    class SpanContext
      module Flags
        SAMPLED = 0x01
        DEBUG = 0x02
      end

      def self.create_parent_context
        trace_id = TraceId.generate
        span_id = TraceId.generate
        flags = Flags::SAMPLED
        new(trace_id: trace_id, span_id: span_id, flags: flags)
      end

      def self.create_from_parent_context(span_context)
        trace_id = span_context.trace_id
        parent_id = span_context.span_id
        flags = span_context.flags
        span_id = TraceId.generate
        new(span_id: span_id, parent_id: parent_id, trace_id: trace_id, flags: flags, baggage: span_context.baggage.dup)
      end

      attr_reader :span_id, :parent_id, :trace_id, :baggage, :flags

      def initialize(span_id:, parent_id: 0, trace_id:, flags:, baggage: {})
        @span_id = span_id
        @parent_id = parent_id
        @trace_id = trace_id
        @baggage = baggage
        @flags = flags
      end

      def inspect
        to_s
      end

      def to_s
        "#<SpanContext @span_id=#{span_id.to_s(16)} " \
          "@parent_id=#{parent_id.to_s(16)} " \
          "@trace_id=#{trace_id.to_s(16)} " \
          "@flags=#{flags}>"
      end
    end
  end
end
