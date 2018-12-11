# frozen_string_literal: true

module Jaeger
  module Client
    class Extractor
      class << self
        def register(format, klass)
          extractors[format] = klass
        end

        def extract(format, carrier)
          if extractors[format]
            extractors[format].extract(carrier)
          else
            warn "Jaeger::Client with format #{format} is not supported yet"
            nil
          end
        end

        def extractors
          @extractors ||= {}
        end
      end
    end
  end
end
