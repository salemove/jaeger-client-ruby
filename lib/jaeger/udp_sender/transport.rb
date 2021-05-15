# frozen_string_literal: true

module Jaeger
  class UdpSender
    class Transport
      FLAGS = 0

      def initialize(host, port, logger:)
        @socket = UDPSocket.new
        @host = host
        @port = port
        @logger = logger
        @buffer = ::Thrift::MemoryBufferTransport.new
      end

      def write(str)
        @buffer.write(str)
      end

      def flush
        data = @buffer.read(@buffer.available)
        send_bytes(data)
      end

      def open; end

      def close; end

      private

      def send_bytes(bytes)
        @socket.send(bytes, FLAGS, @host, @port)
        @socket.flush
      rescue Errno::ECONNREFUSED
        @logger.warn 'Unable to connect to Jaeger Agent'
      rescue StandardError => e
        @logger.warn "Unable to send spans: #{e.message}"
      end
    end
  end
end
