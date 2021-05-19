# frozen_string_literal: true

$LOAD_PATH.push("#{File.dirname(__FILE__)}/../../thrift/gen-rb")

require 'opentracing'
require 'jaeger/thrift/agent'
require 'logger'
require 'time'
require 'net/http'
require 'cgi'
require 'json'

require_relative 'tracer'
require_relative 'span'
require_relative 'span_context'
require_relative 'scope'
require_relative 'scope_manager'
require_relative 'trace_id'
require_relative 'udp_sender'
require_relative 'http_sender'
require_relative 'reporters'
require_relative 'client/version'
require_relative 'samplers'
require_relative 'encoders/thrift_encoder'
require_relative 'injectors'
require_relative 'extractors'
require_relative 'rate_limiter'
require_relative 'thrift_tag_builder'
require_relative 'recurring_executor'

module Jaeger
  module Client
    # We initially had everything under Jaeger::Client namespace. This however
    # was not very useful and was removed. These assignments are here for
    # backwards compatibility. Fine to remove in the next major version.
    UdpSender = Jaeger::UdpSender
    HttpSender = Jaeger::HttpSender
    Encoders = Jaeger::Encoders
    Samplers = Jaeger::Samplers
    Reporters = Jaeger::Reporters
    Injectors = Jaeger::Injectors
    Extractors = Jaeger::Extractors

    DEFAULT_FLUSH_INTERVAL = 10

    def self.build(service_name:,
                   host: '127.0.0.1',
                   port: 6831,
                   flush_interval: DEFAULT_FLUSH_INTERVAL,
                   sampler: Samplers::Const.new(true),
                   logger: Logger.new($stdout),
                   sender: nil,
                   reporter: nil,
                   injectors: {},
                   extractors: {},
                   tags: {})
      encoder = Encoders::ThriftEncoder.new(service_name: service_name, tags: tags, logger: logger)

      if sender
        warn '[DEPRECATION] Passing `sender` directly to Jaeger::Client.build is deprecated.' \
          'Please use `reporter` instead.'
      end

      reporter ||= Reporters::RemoteReporter.new(
        sender: sender || UdpSender.new(host: host, port: port, encoder: encoder, logger: logger),
        flush_interval: flush_interval
      )

      Tracer.new(
        reporter: reporter,
        sampler: sampler,
        injectors: Injectors.prepare(injectors),
        extractors: Extractors.prepare(extractors)
      )
    end
  end
end
