Jaeger::Client
================
[![Gem Version](https://badge.fury.io/rb/jaeger-client.svg)](https://rubygems.org/gems/jaeger-client)
[![Build Status](https://travis-ci.org/salemove/jaeger-client-ruby.svg)](https://travis-ci.org/salemove/jaeger-client-ruby)

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

span = OpenTracing.start_span('span name')
span.finish
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/salemove/jaeger-client-ruby


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

