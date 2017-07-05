module Jaeger
  module Client
    # SpanContext holds the data for a span that gets inherited to child spans
    class SpanContext
      def self.create_parent_context
        trace_id = TraceId.generate
        span_id = TraceId.generate
        new(trace_id: trace_id, span_id: span_id)
      end

      def self.create_from_parent_context(span_context)
        trace_id = span_context.trace_id
        parent_id = span_context.span_id
        span_id = TraceId.generate
        new(span_id: span_id, parent_id: parent_id, trace_id: trace_id)
      end

      attr_reader :span_id, :parent_id, :trace_id, :baggage, :flags

      def initialize(span_id:, parent_id: 0, trace_id:, baggage: {})
        @span_id = span_id
        @parent_id = parent_id
        @trace_id = trace_id
        @baggage = baggage
        @flags = 0
      end

      def inspect
        to_s
      end

      def to_s
        "#<SpanContext @span_id=#{span_id.to_s(16)} " +
          "@parent_id=#{parent_id.to_s(16)} " +
          "@trace_id=#{trace_id.to_s(16)} " +
          "@flags=#{flags}>"
      end
    end
  end
end
