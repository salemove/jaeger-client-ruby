# frozen_string_literal: true

require_relative 'span/thrift_tag_builder'
require_relative 'span/thrift_log_builder'

module Jaeger
  module Client
    class Span
      attr_accessor :operation_name

      attr_reader :context, :start_time, :tags, :logs

      # Creates a new {Span}
      #
      # @param context [SpanContext] the context of the span
      # @param context [String] the operation name
      # @param collector [Collector] span collector
      #
      # @return [Span] a new Span
      def initialize(context, operation_name, collector, start_time: Time.now, tags: {})
        @context = context
        @operation_name = operation_name
        @collector = collector
        @start_time = start_time
        @tags = tags.map { |key, value| ThriftTagBuilder.build(key, value) }
        @logs = []
      end

      # Set a tag value on this span
      #
      # @param key [String] the key of the tag
      # @param value [String, Numeric, Boolean] the value of the tag. If it's not
      # a String, Numeric, or Boolean it will be encoded with to_s
      def set_tag(key, value)
        # Using Thrift::Tag to avoid unnecessary memory allocations
        @tags << ThriftTagBuilder.build(key, value)
      end

      # Set a baggage item on the span
      #
      # @param key [String] the key of the baggage item
      # @param value [String] the value of the baggage item
      def set_baggage_item(key, value)
        self
      end

      # Get a baggage item
      #
      # @param key [String] the key of the baggage item
      #
      # @return Value of the baggage item
      def get_baggage_item(key)
        nil
      end

      # Add a log entry to this span
      #
      # @deprecated Use {#log_kv} instead.
      def log(*args)
        warn 'Span#log is deprecated. Please use Span#log_kv instead.'
        log_kv(*args)
      end

      # Add a log entry to this span
      #
      # @param timestamp [Time] time of the log
      # @param fields [Hash] Additional information to log
      def log_kv(timestamp: Time.now, **fields)
        # Using Thrift::Log to avoid unnecessary memory allocations
        @logs << ThriftLogBuilder.build(timestamp, fields)
        nil
      end

      # Finish the {Span}
      #
      # @param end_time [Time] custom end time, if not now
      def finish(end_time: Time.now)
        @collector.send_span(self, end_time)
      end
    end
  end
end
