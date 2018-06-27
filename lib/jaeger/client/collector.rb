require 'thread'

module Jaeger
  module Client
    class Collector
      def initialize
        @buffer = Buffer.new
      end

      def send_span(span, end_time)
        context = span.context
        start_ts, duration = build_timestamps(span, end_time)

        @buffer << Jaeger::Thrift::Span.new(
          'traceIdLow' => context.trace_id,
          'traceIdHigh' => 0,
          'spanId' => context.span_id,
          'parentSpanId' => context.parent_id,
          'operationName' => span.operation_name,
          'references' => build_references(span.references),
          'flags' => context.flags,
          'startTime' => start_ts,
          'duration' => duration,
          'tags' => build_tags(span.tags),
          'logs' => build_logs(span.logs)
        )
      end

      def retrieve
        @buffer.retrieve
      end

      private
      def build_references(references)
        references.map do |ref|
          Jaeger::Thrift::SpanRef.new(
            'refType' => span_ref_type(ref.type),
            'traceIdLow' => ref.context.trace_id,
            'traceIdHigh' => 0,
            'spanId' => ref.context.span_id
          )
        end
      end

        def span_ref_type(type)
          case type
            when OpenTracing::Reference::CHILD_OF
              Jaeger::Thrift::SpanRefType::CHILD_OF
            when OpenTracing::Reference::FOLLOWS_FROM
              Jaeger::Thrift::SpanRefType::FOLLOWS_FROM
            else
              warn "Jaeger::Client with format #{type} is not supported yet"
              nil
          end
        end

      def build_tags(tags)
        tags.map { |name, value| build_tag(name, value) }
      end

      def build_logs(logs)
        logs.map do |timestamp:, fields:|
          Jaeger::Thrift::Log.new(
            'timestamp' => (timestamp.to_f * 1_000_000).to_i,
            'fields' => fields.map { |name, value| build_tag(name, value) }
          )
        end
      end

      def build_tag(name, value)
        Jaeger::Thrift::Tag.new(
          'key' => name.to_s,
          'vType' => Jaeger::Thrift::TagType::STRING,
          'vStr' => value.to_s
        )
      end

      def build_timestamps(span, end_time)
        start_ts = (span.start_time.to_f * 1_000_000).to_i
        end_ts = (end_time.to_f * 1_000_000).to_i
        duration = end_ts - start_ts
        [start_ts, duration]
      end

      class Buffer
        def initialize
          @buffer = []
          @mutex = Mutex.new
        end

        def <<(element)
          @mutex.synchronize do
            @buffer << element
            true
          end
        end

        def retrieve
          @mutex.synchronize do
            elements = @buffer.dup
            @buffer.clear
            elements
          end
        end
      end
    end
  end
end
