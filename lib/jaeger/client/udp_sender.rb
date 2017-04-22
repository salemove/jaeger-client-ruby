require 'jaeger/thrift/agent'
require 'thread'

module Jaeger
  module Client
    class UdpSender
      def initialize(service_name, host, port)
        @service_name = service_name

        emitter = SocketEmitter.new(host, port)
        emitter.start
        transport = Transport.new(emitter)
        protocol = ::Thrift::CompactProtocol.new(transport)

        @client = Jaeger::Thrift::Agent::Client.new(protocol)
      end

      def send_span(span, end_time)
        context = span.context
        start_ts, duration = build_timestamps(span, end_time)

        thrift_span = Jaeger::Thrift::Span.new(
          'traceIdLow' => context.trace_id,
          'traceIdHigh' => context.trace_id,
          'spanId' => context.span_id,
          'parentSpanId' => context.parent_id || 0,
          'operationName' => span.operation_name,
          'references' => [],
          'flags' => context.flags,
          'startTime' => start_ts,
          'duration' => duration,
          'tags' => build_tags(span.tags),
          'logs' => build_logs(span.logs)
        )
        batch = Jaeger::Thrift::Batch.new(
          'process' => Jaeger::Thrift::Process.new(
            'serviceName' => @service_name,
            'tags' => [],
          ),
          'spans' => [thrift_span]
        )

        @client.emitBatch(batch)
      end

      private

      def build_tags(tags)
        tags.map {|name, value| build_tag(name, value)}
      end

      def build_logs(logs)
        logs.map do |timestamp:, fields:|
          Jaeger::Thrift::Log.new(
            'timestamp' => (timestamp.to_f * 1_000_000).to_i,
            'fields' => fields.map {|name, value| build_tag(name, value)}
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

      class Transport
        def initialize(emitter)
          @emitter = emitter
          @buffer = ::Thrift::MemoryBufferTransport.new
        end

        def write(str)
          @buffer.write(str)
        end

        def flush
          @emitter.emit(@buffer.read(@buffer.available))
          @buffer.reset_buffer
        end

        def open; end
        def close; end
      end

      class SocketEmitter
        FLAGS = 0

        def initialize(host, port)
          @socket = UDPSocket.new
          @socket.connect(host, port)
          @encoded_spans = Queue.new
        end

        def emit(encoded_spans)
          @encoded_spans << encoded_spans
        end

        def start
          # Sending spans in a separate thread to avoid blocking the main thread.
          Thread.new do
            while encoded_span = @encoded_spans.pop
              send_bytes(encoded_span)
            end
          end
        end

        private

        def send_bytes(bytes)
          @socket.send(bytes, FLAGS)
          @socket.flush
        rescue Errno::ECONNREFUSED
          warn 'Unable to connect to Jaeger Agent'
        rescue => e
          warn "Unable to send spans: #{e.message}"
        end
      end
    end
  end
end
