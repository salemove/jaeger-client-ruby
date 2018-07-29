# frozen_string_literal: true

module Jaeger
  module Client
    # SpanContext holds the data for a span that gets inherited to child spans
    class SpanContext
      MAX_SIGNED_ID = (1 << 63) - 1
      MAX_UNSIGNED_ID = (1 << 64)
      ID_ATTRIBUTES = %i[span_id parent_id trace_id]

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

      attr_reader :baggage, :flags, *ID_ATTRIBUTES

      ID_ATTRIBUTES.each do |attribute|
        define_method "thrift_#{attribute}" do
          id_to_thrift_int(self.public_send(attribute))
        end
      end

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

      def inspect
        to_s
      end

      def to_s
        "#<SpanContext @span_id=#{span_id.to_s(16)} " \
          "@parent_id=#{parent_id.to_s(16)} " \
          "@trace_id=#{trace_id.to_s(16)} " \
          "@flags=#{flags}>"
      end

      private

      def id_to_thrift_int(id)
        return unless id

        puts id
        id -= MAX_UNSIGNED_ID if id > MAX_SIGNED_ID
        id
      end
    end
  end
end
