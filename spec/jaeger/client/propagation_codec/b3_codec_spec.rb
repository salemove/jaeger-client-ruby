require 'spec_helper'

describe Jaeger::Client::PropagationCodec::B3Codec do
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
        expect(carrier['x-b3-traceid']).to eq(span_context.trace_id.to_s(16).rjust(16, '0'))
        expect(carrier['x-b3-spanid']).to eq(span_context.span_id.to_s(16).rjust(16, '0'))
        expect(carrier['x-b3-parentspanid']).to eq(span_context.parent_id.to_s(16).rjust(16, '0'))
        expect(carrier['x-b3-sampled']).to eq(span_context.flags.to_s(16))
      end
    end

    context 'when sampler flag is DEBUG' do
      before do
        # mock flags since the test tracer doesn't have this yet
        allow(span_context).to receive(:flags).and_return(0x02)

        codec.inject(span_context, carrier)
      end

      it 'sets the x-b3-flags header' do
        expect(carrier).to have_key 'x-b3-flags'
        expect(carrier['x-b3-flags']).to eq '1'
      end

      it 'does not set the x-b3-sampled header' do
        expect(carrier).not_to have_key 'x-b3-sampled'
      end
    end

    context 'when span context IDs are longer than 16 characters' do
      before do
        # mock fields, since they are read only
        allow(span_context).to receive(:trace_id).and_return(0xFFFFFFFFFFFFFFFFF)
        allow(span_context).to receive(:span_id).and_return(0xFFFFFFFFFFFFFFFFF)
        allow(span_context).to receive(:parent_id).and_return(0xFFFFFFFFFFFFFFFFF)

        codec.inject(span_context, carrier)
      end

      it 'pads the hex id strings to 32 characters' do
        expect(carrier['x-b3-traceid'].length).to eq 32
        expect(carrier['x-b3-spanid'].length).to eq 32
        expect(carrier['x-b3-parentspanid'].length).to eq 32
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
      context 'when header x-b3-sampled is present' do
        let(:carrier) { Net::HTTPResponse.new({}, 200, "") }

        before do
          carrier['x-b3-traceid'] = trace_id
          carrier['x-b3-spanid'] = span_id
          carrier['x-b3-parentspanid'] = parent_id
          carrier['x-b3-sampled'] = flags
        end

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

      context 'when header x-b3-flags is present' do
        let(:carrier) { Net::HTTPResponse.new({}, 200, "") }

        before do
          carrier['x-b3-traceid'] = trace_id
          carrier['x-b3-spanid'] = span_id
          carrier['x-b3-parentspanid'] = parent_id
          carrier['x-b3-flags'] = '1'
        end

        let(:span_context) { codec.extract_text_map(carrier) }

        it 'sets the DEBUG flag' do
          expect(span_context.flags).to eq(0x02)
        end
      end
    end

    describe '#extract_rack' do
      context 'when header HTTP_X_B3_SAMPLED is present' do
        let(:carrier) { { 'HTTP_X_B3_TRACEID' => trace_id,
                          'HTTP_X_B3_SPANID' => span_id,
                          'HTTP_X_B3_PARENTSPANID' => parent_id,
                          'HTTP_X_B3_SAMPLED' => flags } }

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

      context 'when header HTTP_X_B3_FLAGS is present' do
        let(:carrier) { { 'HTTP_X_B3_TRACEID' => trace_id,
                          'HTTP_X_B3_SPANID' => span_id,
                          'HTTP_X_B3_PARENTSPANID' => parent_id,
                          'HTTP_X_B3_FLAGS' => '1' } }

        let(:span_context) { codec.extract_rack(carrier) }

        it 'sets the DEBUG flag' do
          expect(span_context.flags).to eq(0x02)
        end
      end
    end
  end
end
