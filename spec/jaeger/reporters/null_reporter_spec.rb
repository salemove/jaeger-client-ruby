require 'spec_helper'

RSpec.describe Jaeger::Client::Reporters::NullReporter do
  describe '#report' do
    it 'does nothing' do
      span = instance_double(Jaeger::Client::Span)
      expect { described_class.new.report(span) }.not_to raise_error
    end
  end
end
