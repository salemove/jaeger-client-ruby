# frozen_string_literal: true

require_relative 'remote_controlled/instructions_fetcher'

module Jaeger
  module Samplers
    class RemoteControlled
      DEFAULT_REFRESH_INTERVAL = 60
      DEFAULT_SAMPLING_HOST = 'localhost'.freeze
      DEFAULT_SAMPLING_PORT = 5778

      attr_reader :sampler

      def initialize(opts = {})
        @sampler = opts.fetch(:sampler, Probabilistic.new)
        @logger = opts.fetch(:logger, Logger.new($stdout))

        @poll_executor = opts[:poll_executor] || begin
          refresh_interval = opts.fetch(:refresh_interval, DEFAULT_REFRESH_INTERVAL)
          RecurringExecutor.new(interval: refresh_interval)
        end

        @instructions_fetcher = opts[:instructions_fetcher] || begin
          service_name = opts.fetch(:service_name)
          host = opts.fetch(:host, DEFAULT_SAMPLING_HOST)
          port = opts.fetch(:port, DEFAULT_SAMPLING_PORT)
          InstructionsFetcher.new(host: host, port: port, service_name: service_name)
        end
      end

      def sample(*args)
        @poll_executor.start(&method(:poll)) unless @poll_executor.running?

        @sampler.sample(*args)
      end

      def poll
        @logger.debug 'Fetching sampling strategy'

        instructions = @instructions_fetcher.fetch
        handle_instructions(instructions)
      rescue InstructionsFetcher::FetchFailed => e
        @logger.warn "Fetching sampling strategy failed: #{e.message}"
      end

      private

      def handle_instructions(instructions)
        if instructions['operationSampling']
          update_per_operation_sampler(instructions['operationSampling'])
        else
          update_rate_limiting_or_probabilistic_sampler(instructions['strategyType'], instructions)
        end
      end

      def update_per_operation_sampler(instructions)
        strategies = normalize(instructions)

        if @sampler.is_a?(PerOperation)
          @sampler.update(strategies: strategies)
        else
          @sampler = PerOperation.new(strategies: strategies, max_operations: 2000)
        end
      end

      def normalize(instructions)
        {
          default_sampling_probability: instructions['defaultSamplingProbability'],
          default_lower_bound_traces_per_second: instructions['defaultLowerBoundTracesPerSecond'],
          per_operation_strategies: instructions['perOperationStrategies'].map do |strategy|
            {
              operation: strategy['operation'],
              probabilistic_sampling: {
                sampling_rate: strategy['probabilisticSampling']['samplingRate']
              }
            }
          end
        }
      end

      def update_rate_limiting_or_probabilistic_sampler(strategy, instructions)
        case strategy
        when 'PROBABILISTIC'
          update_probabilistic_strategy(instructions['probabilisticSampling'])
        when 'RATE_LIMITING'
          update_rate_limiting_strategy(instructions['rateLimitingSampling'])
        else
          @logger.warn "Unknown sampling strategy #{strategy}"
        end
      end

      def update_probabilistic_strategy(instructions)
        rate = instructions['samplingRate']
        return unless rate

        if @sampler.is_a?(Probabilistic)
          @sampler.update(rate: rate)
          @logger.info "Updated Probabilistic sampler (rate=#{rate})"
        else
          @sampler = Probabilistic.new(rate: rate)
          @logger.info "Updated sampler to Probabilistic (rate=#{rate})"
        end
      end

      def update_rate_limiting_strategy(instructions)
        max_traces_per_second = instructions['maxTracesPerSecond']
        return unless max_traces_per_second

        if @sampler.is_a?(RateLimiting)
          @sampler.update(max_traces_per_second: max_traces_per_second)
          @logger.info "Updated Ratelimiting sampler (max_traces_per_second=#{max_traces_per_second})"
        else
          @sampler = RateLimiting.new(max_traces_per_second: max_traces_per_second)
          @logger.info "Updated sampler to Ratelimiting (max_traces_per_second=#{max_traces_per_second})"
        end
      end
    end
  end
end
