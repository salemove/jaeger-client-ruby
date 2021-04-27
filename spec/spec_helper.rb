require 'bundler/setup'
require 'jaeger/client'
require 'timecop'

require 'webmock/rspec'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  def build_span_context(opts = {})
    Jaeger::SpanContext.new(**{
      trace_id: Jaeger::TraceId.generate,
      span_id: Jaeger::TraceId.generate,
      flags: Jaeger::SpanContext::Flags::SAMPLED
    }.merge(opts))
  end

  def build_span(opts = {})
    span_context = opts.delete(:span_context) || build_span_context
    operation_name = opts.delete(:operation_name) || 'operation-name'
    reporter = opts.delete(:reporter) || Jaeger::Reporters::NullReporter.new

    Jaeger::Span.new(span_context, operation_name, reporter, **opts)
  end
end
