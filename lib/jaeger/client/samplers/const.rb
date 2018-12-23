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
        attr_reader :tags

        def initialize(decision)
          @decision = decision
          @tags = {
            'sampler.type' => 'const',
            'sampler.param' => @decision ? 1 : 0
          }
        end

        def sample?(*)
          @decision
        end
      end
    end
  end
end
