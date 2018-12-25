# frozen_string_literal: true

require_relative 'scope_manager/scope_stack'
require_relative 'scope_manager/scope_identifier'

module Jaeger
  # ScopeManager represents an OpenTracing ScopeManager
  #
  # See http://www.opentracing.io for more information.
  #
  # The ScopeManager interface abstracts both the activation of Span instances
  # via ScopeManager#activate and access to an active Span/Scope via
  # ScopeManager#active
  #
  class ScopeManager
    def initialize
      @scope_stack = ScopeStack.new
    end

    # Make a span instance active
    #
    # @param span [Span] the Span that should become active
    # @param finish_on_close [Boolean] whether the Span should automatically be
    #   finished when Scope#close is called
    # @return [Scope] instance to control the end of the active period for the
    #  Span. It is a programming error to neglect to call Scope#close on the
    #  returned instance.
    def activate(span, finish_on_close: true)
      return active if active && active.span == span
      scope = Scope.new(span, @scope_stack, finish_on_close: finish_on_close)
      @scope_stack.push(scope)
      scope
    end

    # Return active scope
    #
    # If there is a non-null Scope, its wrapped Span becomes an implicit parent
    # (as Reference#CHILD_OF) of any newly-created Span at
    # Tracer#start_active_span or Tracer#start_span time.
    #
    # @return [Scope] the currently active Scope which can be used to access the
    #   currently active Span.
    def active
      @scope_stack.peek
    end
  end
end
