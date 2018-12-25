# frozen_string_literal: true

module Jaeger
  module Reporters
    class CompositeReporter
      def initialize(reporters:)
        @reporters = reporters
      end

      def report(span)
        @reporters.each do |reporter|
          reporter.report(span)
        end
      end
    end
  end
end
