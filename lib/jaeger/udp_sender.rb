# frozen_string_literal: true

require_relative './udp_sender/transport'
require 'socket'

module Jaeger
  class UdpSender
    def initialize(host:, port:, encoder:, logger:, max_packet_size: 65_000)
      @encoder = encoder
      @logger = logger

      transport = Transport.new(host, port)
      @protocol_class = ::Thrift::CompactProtocol
      protocol = @protocol_class.new(transport)
      @client = Jaeger::Thrift::Agent::Client.new(protocol)
      @max_packet_size = max_packet_size
    end

    def send_spans(spans)
      batches = @encoder.encode_limited_size(spans, @protocol_class, @max_packet_size)
      batches.each { |batch| @client.emitBatch(batch) }
    rescue StandardError => error
      @logger.error("Failure while sending a batch of spans: #{error}")
    end
  end
end
