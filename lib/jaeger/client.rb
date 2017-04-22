$LOAD_PATH.push(File.dirname(__FILE__) + '/../../thrift/gen-rb')

require 'opentracing'

require_relative 'client/tracer'
require_relative 'client/span'
require_relative 'client/span_context'
require_relative 'client/carrier'
require_relative 'client/trace_id'
require_relative 'client/udp_sender'

module Jaeger
  module Client
    def self.build(host: '127.0.0.1', port: 6831, service_name:)
      client = UdpSender.new(service_name, host, port)
      Tracer.new(client, service_name)
    end
  end
end
