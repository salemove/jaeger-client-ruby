# frozen_string_literal: true

module Jaeger
  module Reporters
    class RemoteReporter
      class Buffer
        def initialize
          @buffer = []
          @mutex = Mutex.new
        end

        def <<(element)
          @mutex.synchronize do
            @buffer << element
            true
          end
        end

        def retrieve
          @mutex.synchronize do
            elements = @buffer.dup
            @buffer.clear
            elements
          end
        end
      end
    end
  end
end
