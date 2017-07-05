$LOAD_PATH.push(File.dirname(__FILE__) + '/../../thrift/gen-rb')

require 'opentracing'

require_relative 'client/tracer'
require_relative 'client/span'
require_relative 'client/span_context'
require_relative 'client/carrier'
require_relative 'client/trace_id'
require_relative 'client/udp_sender'
require_relative 'client/collector'

module Jaeger
  module Client
    DEFAULT_FLUSH_INTERVAL = 10

    def self.build(host: '127.0.0.1', port: 6831, service_name:, flush_interval: DEFAULT_FLUSH_INTERVAL)
      collector = Collector.new
      sender = UdpSender.new(
        service_name: service_name,
        host: host,
        port: port,
        collector: collector,
        flush_interval: flush_interval
      )
      sender.start
      Tracer.new(collector, sender)
    end
  end
end
