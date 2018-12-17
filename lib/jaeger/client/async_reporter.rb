# frozen_string_literal: true

require 'thread'

require_relative './async_reporter/buffer'

module Jaeger
  module Client
    class AsyncReporter
      def self.create(sender:, flush_interval:)
        new(sender, flush_interval)
      end

      def initialize(sender, flush_interval)
        @sender = sender
        @flush_interval = flush_interval
        @buffer = Buffer.new
      end

      def flush
        spans = @buffer.retrieve
        @sender.send_spans(spans) if spans.any?
        spans
      end

      def report(span)
        return if !span.context.sampled? && !span.context.debug?

        init_reporter_thread
        @buffer << span
      end

      private

      def init_reporter_thread
        return if @initializer_pid == Process.pid

        @initializer_pid = Process.pid
        Thread.new do
          loop do
            flush
            sleep(@flush_interval)
          end
        end
      end
    end
  end
end
