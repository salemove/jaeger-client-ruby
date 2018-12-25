# frozen_string_literal: true

require_relative 'span/thrift_tag_builder'
require_relative 'span/thrift_log_builder'

module Jaeger
  class Span
    attr_accessor :operation_name

    attr_reader :context, :start_time, :end_time, :references, :tags, :logs

    # Creates a new {Span}
    #
    # @param context [SpanContext] the context of the span
    # @param operation_name [String] the operation name
    # @param reporter [#report] span reporter
    #
    # @return [Span] a new Span
    def initialize(context, operation_name, reporter, start_time: Time.now, references: [], tags: {})
      @context = context
      @operation_name = operation_name
      @reporter = reporter
      @start_time = start_time
      @references = references
      @tags = []
      @logs = []

      tags.each { |key, value| set_tag(key, value) }
    end

    # Set a tag value on this span
    #
    # @param key [String] the key of the tag
    # @param value [String, Numeric, Boolean] the value of the tag. If it's not
    # a String, Numeric, or Boolean it will be encoded with to_s
    def set_tag(key, value)
      if key == 'sampling.priority'
        if value.to_i > 0
          return self if @context.debug?

          @context.flags = @context.flags | SpanContext::Flags::SAMPLED | SpanContext::Flags::DEBUG
        else
          @context.flags = @context.flags & ~SpanContext::Flags::SAMPLED
        end
        return self
      end

      # Using Thrift::Tag to avoid unnecessary memory allocations
      @tags << ThriftTagBuilder.build(key, value)

      self
    end

    # Set a baggage item on the span
    #
    # @param key [String] the key of the baggage item
    # @param value [String] the value of the baggage item
    def set_baggage_item(key, value)
      @context.set_baggage_item(key, value)
      self
    end

    # Get a baggage item
    #
    # @param key [String] the key of the baggage item
    #
    # @return Value of the baggage item
    def get_baggage_item(key)
      @context.get_baggage_item(key)
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
      @end_time = end_time
      @reporter.report(self)
    end
  end
end
