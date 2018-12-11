# frozen_string_literal: true

module Jaeger
  module Client
    class Injector
      class TextMap
        class << self
          def inject(span_context, carrier)
            carrier['uber-trace-id'] = [
              span_context.trace_id.to_s(16),
              span_context.span_id.to_s(16),
              span_context.parent_id.to_s(16),
              span_context.flags.to_s(16)
            ].join(':')
          end
        end
      end
    end
  end
end

Jaeger::Client::Injector.register(OpenTracing::FORMAT_TEXT_MAP,
                                  Jaeger::Client::Injector::TextMap)
Jaeger::Client::Injector.register(OpenTracing::FORMAT_RACK,
                                  Jaeger::Client::Injector::TextMap)
