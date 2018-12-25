# frozen_string_literal: true

module Jaeger
  module Reporters
    class InMemoryReporter
      def initialize
        @spans = []
        @mutex = Mutex.new
      end

      def report(span)
        @mutex.synchronize do
          @spans << span
        end
      end

      def spans
        @mutex.synchronize do
          @spans
        end
      end

      def clear
        @mutex.synchronize do
          @spans.clear
        end
      end
    end
  end
end
