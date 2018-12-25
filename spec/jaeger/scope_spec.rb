require 'spec_helper'

RSpec.describe Jaeger::Scope do
  let(:span) { instance_spy(Jaeger::Span) }
  let(:scope_stack) { Jaeger::ScopeManager::ScopeStack.new }
  let(:finish_on_close) { true }
  let(:scope) { described_class.new(span, scope_stack, finish_on_close: finish_on_close) }

  before do
    scope_stack.push(scope)
  end

  describe '#span' do
    it 'returns scope span' do
      scope = described_class.new(span, scope_stack, finish_on_close: true)
      expect(scope.span).to eq(span)
    end
  end

  describe '#close' do
    context 'when finish_on_close is true' do
      let(:finish_on_close) { true }

      it 'finishes the span' do
        scope.close
        expect(scope.span).to have_received(:finish)
      end

      it 'removes the scope from the scope stack' do
        expect(scope_stack.peek).to eq(scope)
        scope.close
        expect(scope_stack.peek).to eq(nil)
      end
    end

    context 'when finish_on_close is false' do
      let(:finish_on_close) { false }

      it 'does not finish the span' do
        scope.close
        expect(scope.span).not_to have_received(:finish)
      end

      it 'removes the scope from the scope stack' do
        expect(scope_stack.peek).to eq(scope)
        scope.close
        expect(scope_stack.peek).to eq(nil)
      end
    end

    context 'when scope is already closed' do
      before { scope.close }

      it 'throws an exception' do
        expect { scope.close }
          .to raise_error("Tried to close already closed span: #{scope.inspect}")
      end
    end
  end
end
