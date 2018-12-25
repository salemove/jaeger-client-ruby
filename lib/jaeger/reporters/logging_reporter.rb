# frozen_string_literal: true

module Jaeger
  module Reporters
    class LoggingReporter
      def initialize(logger: Logger.new($stdout))
        @logger = logger
      end

      def report(span)
        span_info = {
          operation_name: span.operation_name,
          start_time: span.start_time.iso8601,
          end_time: span.end_time.iso8601,
          trace_id: span.context.to_trace_id,
          span_id: span.context.to_span_id
        }
        @logger.info "Span reported: #{span_info}"
      end
    end
  end
end
