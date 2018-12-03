require 'spec_helper'

describe Jaeger::Client::PropagationCodec::JaegerCodec do
  let(:tracer) { Jaeger::Client::Tracer.new(reporter, sampler, codec) }
  let(:reporter) { instance_spy(Jaeger::Client::AsyncReporter) }
  let(:sampler) { Jaeger::Client::Samplers::Const.new(true) }
  let (:codec) { described_class.new }

  describe '#inject' do
    let(:operation_name) { 'operator-name' }
    let(:span) { tracer.start_span(operation_name) }
    let(:span_context) { span.context }
    let(:carrier) { {} }

    context 'when FORMAT_TEXT_MAP' do
      before { codec.inject(span_context, carrier) }

      it 'sets trace information' do
        expect(carrier['uber-trace-id']).to eq(
          [
            span_context.trace_id.to_s(16),
            span_context.span_id.to_s(16),
            span_context.parent_id.to_s(16),
            span_context.flags.to_s(16)
          ].join(':')
        )
      end
    end
  end

  context 'when extracting' do
    let(:hexa_max_uint64) { 'ff' * 8 }
    let(:max_uint64) { 2**64 - 1 }

    let(:operation_name) { 'operator-name' }
    let(:trace_id) { '58a515c97fd61fd7' }
    let(:parent_id) { '8e5a8c5509c8dcc1' }
    let(:span_id) { 'aba8be8d019abed2' }
    let(:flags) { '1' }

    describe '#extract_text_map' do
      let(:carrier) { { 'uber-trace-id' => "#{trace_id}:#{span_id}:#{parent_id}:#{flags}" } }
      let(:span_context) { codec.extract_text_map(carrier) }

      it 'has flags' do
        expect(span_context.flags).to eq(flags.to_i(16))
      end

      context 'when trace-id is a max uint64' do
        let(:trace_id) { hexa_max_uint64 }

        it 'interprets it correctly' do
          expect(span_context.trace_id).to eq(max_uint64)
        end
      end

      context 'when parent-id is a max uint64' do
        let(:parent_id) { hexa_max_uint64 }

        it 'interprets it correctly' do
          expect(span_context.parent_id).to eq(max_uint64)
        end
      end

      context 'when span-id is a max uint64' do
        let(:span_id) { hexa_max_uint64 }

        it 'interprets it correctly' do
          expect(span_context.span_id).to eq(max_uint64)
        end
      end

      context 'when parent-id is 0' do
        let(:parent_id) { '0' }

        it 'sets parent_id to 0' do
          expect(span_context.parent_id).to eq(0)
        end
      end

      context 'when trace-id missing' do
        let(:trace_id) { nil }

        it 'returns nil' do
          expect(span_context).to eq(nil)
        end
      end

      context 'when span-id missing' do
        let(:span_id) { nil }

        it 'returns nil' do
          expect(span_context).to eq(nil)
        end
      end
    end

    describe '#extract_rack' do
      let(:carrier) { { 'HTTP_UBER_TRACE_ID' => "#{trace_id}:#{span_id}:#{parent_id}:#{flags}" } }
      let(:span_context) { codec.extract_rack(carrier) }

      it 'has flags' do
        expect(span_context.flags).to eq(flags.to_i(16))
      end

      context 'when trace-id is a max uint64' do
        let(:trace_id) { hexa_max_uint64 }

        it 'interprets it correctly' do
          expect(span_context.trace_id).to eq(max_uint64)
        end
      end

      context 'when parent-id is a max uint64' do
        let(:parent_id) { hexa_max_uint64 }

        it 'interprets it correctly' do
          expect(span_context.parent_id).to eq(max_uint64)
        end
      end

      context 'when span-id is a max uint64' do
        let(:span_id) { hexa_max_uint64 }

        it 'interprets it correctly' do
          expect(span_context.span_id).to eq(max_uint64)
        end
      end

      context 'when parent-id is 0' do
        let(:parent_id) { '0' }

        it 'sets parent_id to 0' do
          expect(span_context.parent_id).to eq(0)
        end
      end

      context 'when trace-id is missing' do
        let(:trace_id) { nil }

        it 'returns nil' do
          expect(span_context).to eq(nil)
        end
      end

      context 'when span-id is missing' do
        let(:span_id) { nil }

        it 'returns nil' do
          expect(span_context).to eq(nil)
        end
      end
    end
  end
end
