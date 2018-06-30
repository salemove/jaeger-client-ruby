# frozen_string_literal: true

module Jaeger
  module Client
    module Samplers
      # Const sampler
      #
      # A sampler that always makes the same decision for new traces depending
      # on the initialization value. Use `Jaeger::Client::Samplers::Const.new(true)`
      # to mark all new traces as sampled.
      class Const
        def initialize(decision)
          @decision = decision
          @param = decision ? '1' : '0'
        end

        def sample?(*)
          @decision
        end

        def type
          'const'
        end

        attr_reader :param
      end
    end
  end
end
