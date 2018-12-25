require 'spec_helper'

RSpec.describe Jaeger::Reporters::NullReporter do
  describe '#report' do
    it 'does nothing' do
      span = instance_double(Jaeger::Span)
      expect { described_class.new.report(span) }.not_to raise_error
    end
  end
end
