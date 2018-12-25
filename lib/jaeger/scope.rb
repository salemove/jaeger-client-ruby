# frozen_string_literal: true

module Jaeger
  # Scope represents an OpenTracing Scope
  #
  # See http://www.opentracing.io for more information.
  class Scope
    def initialize(span, scope_stack, finish_on_close:)
      @span = span
      @scope_stack = scope_stack
      @finish_on_close = finish_on_close
      @closed = false
    end

    # Return the Span scoped by this Scope
    #
    # @return [Span]
    attr_reader :span

    # Close scope
    #
    # Mark the end of the active period for the current thread and Scope,
    # updating the ScopeManager#active in the process.
    def close
      raise "Tried to close already closed span: #{inspect}" if @closed
      @closed = true

      @span.finish if @finish_on_close
      removed_scope = @scope_stack.pop

      if removed_scope != self # rubocop:disable Style/GuardClause
        raise 'Removed non-active scope, ' \
          "removed: #{removed_scope.inspect}, "\
          "expected: #{inspect}"
      end
    end
  end
end
