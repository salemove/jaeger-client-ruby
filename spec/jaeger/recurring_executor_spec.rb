require 'spec_helper'

describe Jaeger::RecurringExecutor do
  let(:executor) { described_class.new(interval: interval) }
  let(:small_delay) { 0.05 }

  after { executor.stop }

  context 'when interval is set to 0' do
    let(:interval) { 0 }

    it 'executes block only once' do
      count = 0
      executor.start { count += 1 }

      sleep(small_delay)
      expect(count).to eq(1)
    end
  end

  context 'when interval is above 0' do
    let(:interval) { 3 }

    it 'executes block periodically' do
      count = 0

      allow(executor).to receive(:sleep).with(interval) do
        sleep(interval) if count >= 4
      end

      executor.start { count += 1 }

      sleep(small_delay)

      expect(count).to eq(4)
    end
  end
end
