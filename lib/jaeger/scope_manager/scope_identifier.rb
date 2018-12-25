# frozen_string_literal: true

module Jaeger
  class ScopeManager
    # @api private
    class ScopeIdentifier
      def self.generate
        # 65..90.chr are characters between A and Z
        "opentracing_#{(0...8).map { rand(65..90).chr }.join}".to_sym
      end
    end
  end
end
