# frozen_string_literal: true

module Jaeger
  module Client
    class Injector
      class << self
        def register(format, klass)
          injectors[format] = klass
        end

        def inject(span_context, format, carrier)
          if injectors[format]
            injectors[format].inject(span_context, carrier)
          else
            warn "Jaeger::Client with format #{format} is not supported yet"
          end
        end

        def injectors
          @injectors ||= {}
        end
      end
    end
  end
end
