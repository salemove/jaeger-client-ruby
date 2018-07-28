# frozen_string_literal: true

require_relative './udp_sender/transport'
require 'socket'
require 'thread'

module Jaeger
  module Client
    class UdpSender
      def initialize(service_name:, host:, port:, collector:, flush_interval:, logger:)
        @service_name = service_name
        @collector = collector
        @flush_interval = flush_interval
        @logger = logger

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
            'tags' => @tags
          ),
          'spans' => thrift_spans
        )

        @client.emitBatch(batch)
      rescue StandardError => error
        log_error(error, batch)
      end

      def log_error(error, failed_batch)
        return unless @logger

        @logger.error("[jaeger-client] Failure while sending batch: #{failed_batch.inspect} with error: #{error}")
      end
    end
  end
end
