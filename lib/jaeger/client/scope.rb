module Jaeger
  module Client
    # Scope represents an OpenTracing Scope
    #
    # See http://www.opentracing.io for more information.
    class Scope
      def initialize(span, finish_on_close:)
        @span = span
        @finish_on_close = finish_on_close
        @closed = false
      end

      # Return the Span scoped by this Scope
      #
      # @return [Span]
      def span
        @span
      end

      # Mark the end of the active period for the current thread and Scope,
      # updating the ScopeManager#active in the process.
      #
      # NOTE: Calling close more than once on a single Scope instance leads to
      # undefined behavior.
      def close
        return if @closed
        @closed = true
        @span.finish if @finish_on_close
      end
    end
  end
end
