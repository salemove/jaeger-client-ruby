# frozen_string_literal: true

module Jaeger
  module Client
    # SpanContext holds the data for a span that gets inherited to child spans
    class SpanContext
      module Flags
        NONE = 0x00
        SAMPLED = 0x01
        DEBUG = 0x02
      end

      def self.create_parent_context(sampler = Samplers::Const.new(true))
        trace_id = TraceId.generate
        span_id = TraceId.generate
        flags = sampler.sample?(trace_id) ? Flags::SAMPLED : Flags::NONE
        new(trace_id: trace_id, span_id: span_id, flags: flags)
      end

      def self.create_from_parent_context(span_context)
        trace_id = span_context.trace_id
        parent_id = span_context.span_id
        flags = span_context.flags
        span_id = TraceId.generate
        new(span_id: span_id, parent_id: parent_id, trace_id: trace_id, flags: flags)
      end

      attr_reader :span_id, :parent_id, :trace_id, :baggage, :flags

      def initialize(span_id:, parent_id: 0, trace_id:, flags:, baggage: {})
        @span_id = span_id
        @parent_id = parent_id
        @trace_id = trace_id
        @baggage = baggage
        @flags = flags
      end

      def sampled?
        @flags & Flags::SAMPLED == Flags::SAMPLED
      end

      def debug?
        @flags & Flags::DEBUG == Flags::DEBUG
      end

      def to_trace_id
        @to_trace_id ||= @trace_id.to_s(16)
      end

      def to_parent_id
        @to_parent_id ||= @parent_id.zero? ? nil : @parent_id.to_s(16)
      end

      def to_span_id
        @to_span_id ||= @span_id.to_s(16)
      end
    end
  end
end
