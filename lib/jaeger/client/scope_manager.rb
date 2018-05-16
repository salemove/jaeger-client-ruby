module Jaeger
  module Client
    # ScopeManager represents an OpenTracing ScopeManager
    #
    # See http://www.opentracing.io for more information.
    #
    # The ScopeManager interface abstracts both the activation of Span instances
    # via ScopeManager#activate and access to an active Span/Scope via
    # ScopeManager#active
    #
    class ScopeManager
      # Make a span instance active.
      #
      # @param span [Span] the Span that should become active
      # @param finish_on_close [Boolean] whether the Span should automatically be
      #   finished when Scope#close is called
      # @return [Scope] instance to control the end of the active period for the
      #  Span. It is a programming error to neglect to call Scope#close on the
      #  returned instance.
      def activate(span, finish_on_close: true)
        return active if active && active.span == span
        scope = Scope.new(span, finish_on_close: finish_on_close)
        activate_scope(scope)
      end

      # @return [Scope] the currently active Scope which can be used to access the
      # currently active Span.
      #
      # If there is a non-null Scope, its wrapped Span becomes an implicit parent
      # (as Reference#CHILD_OF) of any newly-created Span at Tracer#start_active_span
      # or Tracer#start_span time.
      def active
        Thread.current[:jaeger_active_scope]
      end

      def activate_scope(scope)
        Thread.current[:jaeger_active_scope] = scope
      end
    end
  end
end
