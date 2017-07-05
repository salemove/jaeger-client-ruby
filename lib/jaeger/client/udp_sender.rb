require_relative './udp_sender/transport'
require 'jaeger/thrift/agent'
require 'thread'

module Jaeger
  module Client
    class UdpSender
      def initialize(service_name:, host:, port:, collector:, flush_interval:)
        @service_name = service_name
        @collector = collector
        @flush_interval = flush_interval

        transport = Transport.new(host, port)
        protocol = ::Thrift::CompactProtocol.new(transport)
        @client = Jaeger::Thrift::Agent::Client.new(protocol)
      end

      def start
        # Sending spans in a separate thread to avoid blocking the main thread.
        @thread = Thread.new do
          loop do
            emit_batch(@collector.retrieve)
            sleep @flush_interval
          end
        end
      end

      def stop
        @thread.terminate if @thread
        emit_batch(@collector.retrieve)
      end

      private

      def emit_batch(thrift_spans)
        return if thrift_spans.empty?

        batch = Jaeger::Thrift::Batch.new(
          'process' => Jaeger::Thrift::Process.new(
            'serviceName' => @service_name,
            'tags' => [],
          ),
          'spans' => thrift_spans
        )

        @client.emitBatch(batch)
      end
    end
  end
end
