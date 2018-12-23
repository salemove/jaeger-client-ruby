# frozen_string_literal: true

module Jaeger
  # Executes a given block periodically. The block will be executed only once
  # when interval is set to 0.
  class RecurringExecutor
    def initialize(interval:)
      @interval = interval
    end

    def start(&block)
      raise 'Already running' if @thread

      @thread = Thread.new do
        if @interval <= 0
          yield
        else
          loop do
            yield
            sleep @interval
          end
        end
      end
    end

    def running?
      @thread && @thread.alive?
    end

    def stop
      @thread.kill
      @thread = nil
    end
  end
end
