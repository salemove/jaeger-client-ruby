module Jaeger
  module Client
    class ThriftSender
      class UDPTransport
        FLAGS = 0

        def initialize(host, port)
          @socket = ::UDPSocket.new
          @socket.connect(host, port)
          @buffer = ::Thrift::MemoryBufferTransport.new
          protocol = ::Thrift::CompactProtocol.new(self)
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
