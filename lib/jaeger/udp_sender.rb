# frozen_string_literal: true

require_relative './udp_sender/transport'
require 'socket'

module Jaeger
  class UdpSender
    def initialize(host:, port:, encoder:, logger:)
      @encoder = encoder
      @logger = logger

      transport = Transport.new(host, port)
      @protocol_class = ::Thrift::CompactProtocol
      protocol = @protocol_class.new(transport)
      @client = Jaeger::Thrift::Agent.new(protocol)
    end

    def send_spans(spans)
      batches = @encoder.encode_limited_size(spans, @protocol_class, 8_000)
      batches.each { |batch| @client.emitBatch(batch) }
    rescue StandardError => error
      @logger.error("Failure while sending a batch of spans: #{error}")
    end
  end
end
