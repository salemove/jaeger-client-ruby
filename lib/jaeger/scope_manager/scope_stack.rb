# frozen_string_literal: true

module Jaeger
  class ScopeManager
    # @api private
    class ScopeStack
      def initialize
        # Generate a random identifier to use as the Thread.current key. This is
        # needed so that it would be possible to create multiple tracers in one
        # thread (mostly useful for testing purposes)
        @scope_identifier = ScopeIdentifier.generate
      end

      def push(scope)
        store << scope
      end

      def pop
        store.pop
      end

      def peek
        store.last
      end

      private

      def store
        Thread.current[@scope_identifier] ||= []
      end
    end
  end
end
