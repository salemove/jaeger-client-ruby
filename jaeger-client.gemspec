lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'jaeger/client/version'

Gem::Specification.new do |spec|
  spec.name          = 'jaeger-client'
  spec.version       = Jaeger::Client::VERSION
  spec.authors       = ['SaleMove TechMovers']
  spec.email         = ['techmovers@salemove.com']
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.summary       = 'OpenTracing Tracer implementation for Jaeger in Ruby'
  spec.description   = ''
  spec.homepage      = 'https://github.com/salemove/jaeger-client-ruby'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.required_ruby_version = ['>= 2.7', '< 3.2']

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.10'
  spec.add_development_dependency 'rubocop', '~> 1.25'
  spec.add_development_dependency 'rubocop-rake', '~> 0.6'
  spec.add_development_dependency 'rubocop-rspec', '~> 2.8'
  spec.add_development_dependency 'timecop', '~> 0.9'
  spec.add_development_dependency 'webmock', '~> 3.14'

  spec.add_dependency 'opentracing', '~> 0.3'
  spec.add_dependency 'thrift'
end
