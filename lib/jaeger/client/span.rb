module Jaeger
  module Client
    class Span
      attr_accessor :operation_name

      attr_reader :context, :start_time, :references, :tags, :logs

      # Creates a new {Span}
      #
      # @param context [SpanContext] the context of the span
      # @param context [String] the operation name
      # @param collector [Collector] span collector
      #
      # @return [Span] a new Span
      def initialize(context, operation_name, collector, start_time: Time.now, references: [], tags: {})
        @context = context
        @operation_name = operation_name
        @collector = collector
        @start_time = start_time
        @tags = tags || {}
        @references = Array(references)
        @logs = []
      end

      # Set a tag value on this span
      #
      # @param key [String] the key of the tag
      # @param value [String, Numeric, Boolean] the value of the tag. If it's not
      # a String, Numeric, or Boolean it will be encoded with to_s
      def set_tag(key, value)
        @tags = @tags.merge(key => value)
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
      # @param timestamp [Time] time of the log
      # @param fields [Hash] Additional information to log
      def log(timestamp: Time.now, **fields)
        @logs << { timestamp: timestamp, fields: fields }
      end

      # Finish the {Span}
      #
      # @param end_time [Time] custom end time, if not now
      def finish(end_time: Time.now)
        @collector.send_span(self, end_time)
      end

      private

      def build_binary_annotations
        @tags.map do |name, value|
          { key: name, value: value.to_s }
        end
      end
    end
  end
end
