# frozen_string_literal: true

module Jaeger
  # SpanContext holds the data for a span that gets inherited to child spans
  class SpanContext
    module Flags
      NONE = 0x00
      SAMPLED = 0x01
      DEBUG = 0x02
    end

    def self.create_from_parent_context(span_context)
      new(
        trace_id: span_context.trace_id,
        parent_id: span_context.span_id,
        span_id: TraceId.generate,
        flags: span_context.flags,
        baggage: span_context.baggage.dup
      )
    end

    attr_reader :span_id, :parent_id, :trace_id, :baggage, :flags
    attr_writer :flags

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

    def to_span_id
      @to_span_id ||= @span_id.to_s(16)
    end

    def set_baggage_item(key, value)
      @baggage[key.to_s] = value.to_s
    end

    def get_baggage_item(key)
      @baggage[key.to_s]
    end
  end
end
