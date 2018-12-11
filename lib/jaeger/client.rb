# frozen_string_literal: true

$LOAD_PATH.push(File.dirname(__FILE__) + '/../../thrift/gen-rb')

require 'opentracing'
require 'jaeger/thrift/agent'
require 'logger'

require_relative 'client/tracer'
require_relative 'client/span'
require_relative 'client/span_context'
require_relative 'client/scope'
require_relative 'client/scope_manager'
require_relative 'client/carrier'
require_relative 'client/trace_id'
require_relative 'client/udp_sender'
require_relative 'client/async_reporter'
require_relative 'client/version'
require_relative 'client/samplers'
require_relative 'client/extractor'
require_relative 'client/extractor/base'
require_relative 'client/extractor/rack'
require_relative 'client/extractor/text_map'
require_relative 'client/injector'
require_relative 'client/injector/text_map'
require_relative 'client/encoders/thrift_encoder'

module Jaeger
  module Client
    DEFAULT_FLUSH_INTERVAL = 10

    def self.build(host: '127.0.0.1',
                   port: 6831,
                   service_name:,
                   flush_interval: DEFAULT_FLUSH_INTERVAL,
                   sampler: Samplers::Const.new(true),
                   logger: Logger.new(STDOUT),
                   sender: nil)
      encoder = Encoders::ThriftEncoder.new(service_name: service_name)

      if sender.nil?
        sender = UdpSender.new(host: host, port: port, encoder: encoder, logger: logger)
      end

      reporter = AsyncReporter.create(sender: sender, flush_interval: flush_interval)
      Tracer.new(reporter, sampler)
    end
  end
end
