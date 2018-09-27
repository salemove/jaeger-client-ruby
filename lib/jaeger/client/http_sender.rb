# frozen_string_literal: true

require 'logger'

module Jaeger
  module Client
    class HttpSender
      def initialize(host:, port:, endpoint:, headers:, encoder:, logger: Logger.new(STDOUT))
        @encoder = encoder
        @logger = logger

        @uri = URI(host)
        @uri.port = port
        @uri.path = endpoint
        @uri.query = "format=jaeger.thrift"

        @transport = ::Thrift::HTTPClientTransport.new(@uri.to_s)

        @transport.add_headers(headers)
      end

      def send_spans(spans)
        batch = @encoder.encode(spans)
        @transport.write(::Thrift::Serializer.new.serialize(batch))
        @transport.flush()
      rescue StandardError => error
        @logger.error("Failure while sending a batch of spans: #{error}")
      end
    end
  end
end
