# frozen_string_literal: true

require_relative './udp_sender/transport'
require 'socket'

module Jaeger
  class UdpSender
    def initialize(host:, port:, encoder:, logger:)
      @encoder = encoder
      @logger = logger

      transport = Transport.new(host, port)
      protocol = ::Thrift::CompactProtocol.new(transport)
      @client = Jaeger::Thrift::Agent::Client.new(protocol)
    end

    def send_spans(spans)
      batch = @encoder.encode(spans)
      @client.emitBatch(batch)
    rescue StandardError => error
      @logger.error("Failure while sending a batch of spans: #{error}")
    end
  end
end
