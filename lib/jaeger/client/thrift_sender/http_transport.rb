require 'faraday'
require 'thrift'

module Jaeger
  module Client
    class ThriftSender
      class HttpTransport < ::Thrift::BaseTransport
        PATH = "/api/traces"
        def initialize(uri)
          if uri.is_a?(String)
            @uri = URI.parse(uri)
          else
            @uri = uri
          end
          @uri.path = PATH
          @uri.query = "format=jaeger.thrift"
          @outbuf = ::Thrift::Bytes.empty_byte_buffer
        end

        def emit_batch(batch)
          write(::Thrift::Serializer.new.serialize(batch))
          flush
        end

        def write(str)
          @outbuf << ::Thrift::Bytes.force_binary_encoding(str)
        end

        def flush
          resp = Faraday.post(@uri.to_s) do |req|
            req.headers['content-type'] = 'application/x-thrift'
            req.body = @outbuf
          end
          puts resp.body
        ensure
          @outbuf = ::Thrift::Bytes.empty_byte_buffer
        end

        def open; end
        def close; end
      end
    end
  end
end
