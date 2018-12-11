# frozen_string_literal: true

module Jaeger
  module Client
    class Extractor
      class TextMap < Base
        class << self
          def extract(carrier)
            parse_context(carrier['uber-trace-id'])
          end
        end
      end
    end
  end
end

Jaeger::Client::Extractor.register(OpenTracing::FORMAT_TEXT_MAP,
                                   Jaeger::Client::Extractor::TextMap)
