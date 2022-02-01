Jaeger::Client
================
[![Gem Version](https://badge.fury.io/rb/jaeger-client.svg)](https://rubygems.org/gems/jaeger-client)
[![Build Status](https://github.com/salemove/jaeger-client-ruby/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/salemove/jaeger-client-ruby/actions/workflows/ci.yml?query=branch%3Amaster)

**This project is not actively maintained. Please consider using [OpenTelemetry](https://opentelemetry.io/)**

OpenTracing Tracer implementation for Jaeger in Ruby

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'jaeger-client'
```

## Usage

```ruby
require 'jaeger/client'
OpenTracing.global_tracer = Jaeger::Client.build(host: 'localhost', port: 6831, service_name: 'echo')

OpenTracing.start_active_span('span name') do
  # do something

  OpenTracing.start_active_span('inner span name') do
    # do something else
  end
end

# don't kill the program too soon, allow time for the background reporter to send the traces
sleep 2
```

See [opentracing-ruby](https://github.com/opentracing/opentracing-ruby) for more examples.

### Reporters

#### RemoteReporter (default)

RemoteReporter buffers spans in memory and sends them out of process using Sender.

There are two senders: `UdpSender` (default) and `HttpSender`.

To use `HttpSender`:

```ruby
OpenTracing.global_tracer = Jaeger::Client.build(
  service_name: 'service_name',
  reporter: Jaeger::Reporters::RemoteReporter.new(
    sender: Jaeger::HttpSender.new(
      url: 'http://localhost:14268/api/traces',
      headers: { 'key' => 'value' }, # headers key is optional
      encoder: Jaeger::Encoders::ThriftEncoder.new(service_name: 'service_name')
    ),
    flush_interval: 10
  )
)
```

#### NullReporter

NullReporter ignores all spans.

```ruby
OpenTracing.global_tracer = Jaeger::Client.build(
  service_name: 'service_name',
  reporter: Jaeger::Reporters::NullReporter.new
)
```

#### LoggingReporter

LoggingReporter prints some details about the span using `logger`. This is meant only for debugging. Do not parse and use this information for anything critical. The implemenation can change at any time.

```ruby
OpenTracing.global_tracer = Jaeger::Client.build(
  service_name: 'service_name',
  reporter: Jaeger::Reporters::LoggingReporter.new
)
```

LoggingReporter can also use a custom logger. For this provide logger using `logger` keyword argument.

### Samplers

#### Const sampler

`Const` sampler always makes the same decision for new traces depending on the initialization value. Set `sampler` to: `Jaeger::Samplers::Const.new(true)` to mark all new traces as sampled.

#### Probabilistic sampler

`Probabilistic` sampler samples traces with probability equal to `rate` (must be between 0.0 and 1.0). This can be enabled by setting `Jaeger::Samplers::Probabilistic.new(rate: 0.1)`

#### RateLimiting sampler

`RateLimiting` sampler samples at most `max_traces_per_second`. The distribution of sampled traces follows burstiness of the service, i.e. a service with uniformly distributed requests will have those requests sampled uniformly as well, but if requests are bursty, especially sub-second, then a number of sequential requests can be sampled each second.

Set `sampler` to `Jaeger::Samplers::RateLimiting.new(max_traces_per_second: 100)`

#### GuaranteedThroughputProbabilistic sampler

`GuaranteedThroughputProbabilistic` is a sampler that guarantees a throughput by using a Probabilistic sampler and RateLimiting sampler The RateLimiting sampler is used to establish a lower_bound so that every operation is sampled at least once in the time interval defined by the lower_bound.

Set `sampler` to `Jaeger::Samplers::GuaranteedThroughputProbabilistic.new(lower_bound: 10, rate: 0.001)`

#### PerOperation sampler

`PerOperation` sampler leverages both Probabilistic sampler and RateLimiting sampler via the GuaranteedThroughputProbabilistic sampler. This sampler keeps track of all operations and delegates calls the the respective GuaranteedThroughputProbabilistic sampler.

Set `sampler` to
```ruby
  Jaeger::Samplers::PerOperation.new(
    strategies: {
      per_operation_strategies: [
        { operation: 'GET /articles', probabilistic_sampling: { sampling_rate: 0.5 } },
        { operation: 'POST /articles', probabilistic_sampling: { sampling_rate: 1.0 } }
      ],
      default_sampling_probability: 0.001,
      default_lower_bound_traces_per_second: 1.0 / (10.0 * 60.0)
    },
    max_operations: 1000
  )
```

#### RemoteControlled sampler

`RemoteControlled` sampler is a sampler that is controller by jaeger agent. It starts out with `Probabilistic` sampler. It polls the jaeger-agent and changes sampling strategy accordingly. Set `sampler` to `Jaeger::Client::Samplers::RemoteControlled.new(service_name: 'service_name')`.

RemoteControlled sampler options:

| Param             | Required | Description |
|-------------------|----------|-------------|
| service_name      | x | name of the current service / application, same as given to Tracer |
| sampler           |   | initial sampler to use prior to retrieving strategies from Agent |
| refresh_interval  |   | interval in seconds before sampling strategy refreshes (0 to not refresh, defaults to 60) |
| host              |   | host for jaeger-agent (defaults to 'localhost') |
| port              |   | port for jaeger-agent for SamplingManager endpoint (defaults to 5778) |
| logger            |   | logger for communication between jaeger-agent (default to $stdout logger) |

### TraceContext compatible header propagation

It is possible to use [W3C Trace Context](https://www.w3.org/TR/trace-context/#overview) headers to propagate the tracing information.

To set it up you need to change FORMAT_RACK injector and extractor.

```ruby
OpenTracing.global_tracer = Jaeger::Client.build(
  service_name: 'service_name',
  injectors: {
    OpenTracing::FORMAT_RACK => [Jaeger::Injectors::TraceContextRackCodec]
  },
  extractors: {
    OpenTracing::FORMAT_RACK => [Jaeger::Extractors::TraceContextRackCodec]
  }
)
```

### Zipkin HTTP B3 compatible header propagation

Jaeger Tracer supports Zipkin B3 Propagation HTTP headers, which are used by a lot of Zipkin tracers. This means that you can use Jaeger in conjunction with OpenZipkin tracers.

To set it up you need to change FORMAT_RACK injector and extractor.

```ruby
OpenTracing.global_tracer = Jaeger::Client.build(
  service_name: 'service_name',
  injectors: {
    OpenTracing::FORMAT_RACK => [Jaeger::Injectors::B3RackCodec]
  },
  extractors: {
    OpenTracing::FORMAT_RACK => [Jaeger::Extractors::B3RackCodec]
  }
)
```

It's also possible to set up multiple injectors and extractors. Each injector will be called in sequence. Note that if multiple injectors are using the same keys then the values will be overwritten.

If multiple extractors is used then the span context from the first match will be returned.

### Process Tags

Jaeger Tracer allows you to define process level tags. By default the tracer provides `jaeger.version`, `ip` and `hostname`. You may want to overwrite `ip` or `hostname` if the tracer cannot auto-detect them.

```ruby
OpenTracing.global_tracer = Jaeger::Client.build(
  service_name: 'service_name',
  tags: {
    'hostname' => 'custom-hostname',
    'custom_tag' => 'custom-tag-value'
  }
)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/salemove/jaeger-client-ruby


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

