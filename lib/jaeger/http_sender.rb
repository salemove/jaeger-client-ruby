# frozen_string_literal: true

require 'logger'

module Jaeger
  class HttpSender
    def initialize(url:, encoder:, headers: {}, logger: Logger.new($stdout))
      @encoder = encoder
      @logger = logger

      @uri = URI(url)
      @uri.query = 'format=jaeger.thrift'

      @transport = ::Thrift::HTTPClientTransport.new(@uri.to_s)
      @transport.add_headers(headers)

      @serializer = ::Thrift::Serializer.new
    end

    def send_spans(spans)
      batch = @encoder.encode(spans)
      @transport.write(@serializer.serialize(batch))
      @transport.flush
    rescue StandardError => e
      @logger.error("Failure while sending a batch of spans: #{e}")
    end
  end
end
