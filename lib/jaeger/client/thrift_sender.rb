require_relative './thrift_sender/udp_transport'
require_relative './thrift_sender/http_transport'
require 'jaeger/thrift/agent'
require 'socket'
require 'thread'

module Jaeger
  module Client
    class ThriftSender
      def initialize(service_name:, collector:, flush_interval:, transport:, flush_span_chunk_limit: 1)
        @service_name = service_name
        @collector = collector
        @flush_interval = flush_interval
        @transport = transport
        @flush_span_chunk_limit = flush_span_chunk_limit

        @tags = [
          Jaeger::Thrift::Tag.new(
            'key' => 'jaeger.version',
            'vType' => Jaeger::Thrift::TagType::STRING,
            'vStr' => 'Ruby-' + Jaeger::Client::VERSION
          ),
          Jaeger::Thrift::Tag.new(
            'key' => 'hostname',
            'vType' => Jaeger::Thrift::TagType::STRING,
            'vStr' => Socket.gethostname
          )
        ]
        ipv4 = Socket.ip_address_list.find { |ai| ai.ipv4? && !ai.ipv4_loopback? }
        unless ipv4.nil?
          @tags << Jaeger::Thrift::Tag.new(
            'key' => 'ip',
            'vType' => Jaeger::Thrift::TagType::STRING,
            'vStr' => ipv4.ip_address
          )
        end
      end

      def start
        # Sending spans in a separate thread to avoid blocking the main thread.
        @thread = Thread.new do
          loop do
            loop do
              data = @collector.retrieve(@flush_span_chunk_limit)
              break if !data.present?
              emit_batch(data)
            end
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
            'tags' => @tags
          ),
          'spans' => thrift_spans
        )

        @transport.emit_batch(batch)
      end
    end
  end
end
