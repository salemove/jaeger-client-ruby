require 'bundler/setup'
require 'jaeger/client'
require 'timecop'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  def build_span_context(opts = {})
    Jaeger::Client::SpanContext.new({
      trace_id: Jaeger::Client::TraceId.generate,
      span_id: Jaeger::Client::TraceId.generate,
      flags: Jaeger::Client::SpanContext::Flags::SAMPLED
    }.merge(opts))
  end
end
