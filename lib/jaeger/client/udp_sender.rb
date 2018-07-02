# frozen_string_literal: true

require_relative './udp_sender/transport'
require 'socket'
require 'thread'

module Jaeger
  module Client
    class UdpSender
      def initialize(service_name:, host:, port:, collector: , flush_span_chunk_limit:)
        @service_name = service_name
        @collector = collector
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

        transport = Transport.new(host, port)
        protocol = ::Thrift::CompactProtocol.new(transport)
        @client = Jaeger::Thrift::Agent::Client.new(protocol)
      end

      def start
        # Sending spans in a separate thread to avoid blocking the main thread.
        @thread = Thread.new do
          loop do
              spans = @collector.retrieve(@flush_span_chunk_limit)
              while !spans.empty?
                emit_batch(spans)
                # There is need to wait for a signal, lets will empty the queue!
                spans = @collector.retrieve(@flush_span_chunk_limit, false)
              end
          end
        end
      end

      def stop
        @thread.terminate if @thread
        loop do # Continue until there is no more information left in queue
          spans = @collector.retrieve(@flush_span_chunk_limit, false)
          break if spans.empty?
          emit_batch(spans)
        end
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
      end
    end
  end
end
