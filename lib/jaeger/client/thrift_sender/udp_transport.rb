module Jaeger
  module Client
    class ThriftSender
      class UDPTransport
        FLAGS = 0

        PROTOCOL_COMPACT = 0
        PROTOCOL_BINARY = 1

        def initialize(host, port, protocol = PROTOCOL_COMPACT)
          @socket = ::UDPSocket.new
          @socket.connect(host, port)
          @buffer = ::Thrift::MemoryBufferTransport.new
          if protocol == PROTOCOL_BINARY
            protocol = ::Thrift::BinaryProtocol.new(self)
          else
            protocol = ::Thrift::CompactProtocol.new(self)
          end

          @client = Jaeger::Thrift::Agent::Client.new(protocol)
        end

        def emit_batch(batch)
          @client.emitBatch(batch)
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
          @socket.send(bytes, FLAGS)
          @socket.flush
        rescue Errno::ECONNREFUSED
          warn 'Unable to connect to Jaeger Agent'
        rescue StandardError => e
          warn "Unable to send spans: #{e.message}"
        end
      end
    end
  end
end
