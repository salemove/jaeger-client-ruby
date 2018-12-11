# frozen_string_literal: true

module Jaeger
  module Client
    class Extractor
      class Rack < Base
        class << self
          def extract(carrier)
            parse_context(carrier['HTTP_UBER_TRACE_ID'])
          end
        end
      end
    end
  end
end

Jaeger::Client::Extractor.register(OpenTracing::FORMAT_RACK,
                                   Jaeger::Client::Extractor::Rack)
