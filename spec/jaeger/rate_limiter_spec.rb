require 'spec_helper'

RSpec.describe Jaeger::RateLimiter do
  let(:start_time) { Time.now }

  before { Timecop.freeze(start_time) }

  after { Timecop.return }

  describe '#check_credit' do
    it 'returns false if item cost is higher than balance' do
      limiter = build_limiter(credits_per_second: 5)
      expect(limiter.check_credit(6)).to eq(false)
    end

    it 'returns true until there is credit left' do
      limiter = build_limiter(credits_per_second: 2)
      expect(limiter.check_credit(1.0)).to eq(true)
      expect(limiter.check_credit(1.0)).to eq(true)
      expect(limiter.check_credit(1.0)).to eq(false)
    end

    it 'returns true when there is enough credit' do
      limiter = build_limiter(credits_per_second: 2)

      # use all credit
      expect(limiter.check_credit(1.0)).to eq(true)
      expect(limiter.check_credit(1.0)).to eq(true)
      expect(limiter.check_credit(1.0)).to eq(false)

      # move time 250ms forward, not enough credits to pay for one sample
      Timecop.travel(start_time + 0.25)
      expect(limiter.check_credit(1.0)).to eq(false)

      # move time 250ms forward, now enough credits to pay for one sample
      Timecop.travel(start_time + 0.5)
      expect(limiter.check_credit(1.0)).to eq(true)
      expect(limiter.check_credit(1.0)).to eq(false)

      # move time 5s forward, enough to accumulate credits for 10 samples,
      # but it should still be capped at 2
      Timecop.travel(start_time + 5.5)
      expect(limiter.check_credit(1.0)).to eq(true)
      expect(limiter.check_credit(1.0)).to eq(true)
      expect(limiter.check_credit(1.0)).to eq(false)
    end
  end

  describe '#update' do
    context 'when balance was full before the update' do
      it 'keeps the new balance full' do
        limiter = build_limiter(credits_per_second: 1)
        expect(limiter.check_credit(1.0)).to eq(true)

        limiter.update(credits_per_second: 2, max_balance: 2)
        expect(limiter.check_credit(1.0)).to eq(false)
      end
    end

    context 'when balance was half full before the update' do
      it 'marks the new balance half full' do
        limiter = build_limiter(credits_per_second: 2)
        expect(limiter.check_credit(1.0)).to eq(true)

        limiter.update(credits_per_second: 4, max_balance: 4)
        expect(limiter.check_credit(1.0)).to eq(true)
        expect(limiter.check_credit(1.0)).to eq(true)
        expect(limiter.check_credit(1.0)).to eq(false)
      end
    end
  end

  def build_limiter(credits_per_second:, **opts)
    described_class.new(**{
      credits_per_second: credits_per_second,
      max_balance: credits_per_second
    }.merge(opts))
  end
end
