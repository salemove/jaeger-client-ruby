# frozen_string_literal: true

module Jaeger
  # RateLimiter is based on leaky bucket algorithm, formulated in terms of a
  # credits balance that is replenished every time check_credit() method is
  # called (tick) by the amount proportional to the time elapsed since the
  # last tick, up to the max_balance. A call to check_credit() takes a cost
  # of an item we want to pay with the balance. If the balance exceeds the
  # cost of the item, the item is "purchased" and the balance reduced,
  # indicated by returned value of true. Otherwise the balance is unchanged
  # and return false.
  #
  # This can be used to limit a rate of messages emitted by a service by
  # instantiating the Rate Limiter with the max number of messages a service
  # is allowed to emit per second, and calling check_credit(1.0) for each
  # message to determine if the message is within the rate limit.
  #
  # It can also be used to limit the rate of traffic in bytes, by setting
  # credits_per_second to desired throughput as bytes/second, and calling
  # check_credit() with the actual message size.
  class RateLimiter
    def initialize(credits_per_second:, max_balance:)
      @credits_per_second = credits_per_second
      @max_balance = max_balance
      @balance = max_balance
      @last_tick = Time.now
    end

    def check_credit(item_cost)
      update_balance

      return false if @balance < item_cost

      @balance -= item_cost
      true
    end

    def update(credits_per_second:, max_balance:)
      update_balance

      @credits_per_second = credits_per_second

      # The new balance should be proportional to the old balance
      @balance = max_balance * @balance / @max_balance
      @max_balance = max_balance
    end

    private

    def update_balance
      current_time = Time.now
      elapsed_time = current_time - @last_tick
      @last_tick = current_time

      @balance += elapsed_time * @credits_per_second
      return if @balance <= @max_balance

      @balance = @max_balance
    end
  end
end
