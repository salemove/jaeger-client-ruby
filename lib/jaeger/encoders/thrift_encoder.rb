# frozen_string_literal: true

module Jaeger
  module Encoders
    class ThriftEncoder
      def initialize(service_name:, tags: {})
        @service_name = service_name
        @tags = prepare_tags(tags)
        @process = Jaeger::Thrift::Process.new('serviceName' => @service_name, 'tags' => @tags)
      end

      def encode(spans)
        encode_batch(spans.map(&method(:encode_span)))
      end

      def encode_limited_size(spans, protocol_class, max_message_length)
        batches = []
        current_batch = []
        current_batch_size = 0
        spans.each do |span|
          encoded_span = encode_span(span)
          encoded_span_size = span_byte_length(encoded_span, protocol_class)
          if encoded_span_size + current_batch_size > max_message_length && !current_batch.empty?
            batches << encode_batch(current_batch)
            current_batch = []
            current_batch_size = 0
          end
          current_batch << encoded_span
          current_batch_size += encoded_span_size
        end
        batches << encode_batch(current_batch) unless current_batch.empty?
        batches
      end

      private

      def encode_batch(encoded_spans)
        Jaeger::Thrift::Batch.new('process' => @process, 'spans' => encoded_spans)
      end

      def encode_span(span)
        context = span.context
        start_ts, duration = build_timestamps(span)

        Jaeger::Thrift::Span.new(
          'traceIdLow' => TraceId.uint64_id_to_int64(context.trace_id),
          'traceIdHigh' => 0,
          'spanId' => TraceId.uint64_id_to_int64(context.span_id),
          'parentSpanId' => TraceId.uint64_id_to_int64(context.parent_id),
          'operationName' => span.operation_name,
          'references' => build_references(span.references || []),
          'flags' => context.flags,
          'startTime' => start_ts,
          'duration' => duration,
          'tags' => span.tags,
          'logs' => span.logs
        )
      end

      def build_references(references)
        references.map do |ref|
          Jaeger::Thrift::SpanRef.new(
            'refType' => span_ref_type(ref.type),
            'traceIdLow' => TraceId.uint64_id_to_int64(ref.context.trace_id),
            'traceIdHigh' => 0,
            'spanId' => TraceId.uint64_id_to_int64(ref.context.span_id)
          )
        end
      end

      def build_timestamps(span)
        start_ts = (span.start_time.to_f * 1_000_000).to_i
        end_ts = (span.end_time.to_f * 1_000_000).to_i
        duration = end_ts - start_ts
        [start_ts, duration]
      end

      def span_ref_type(type)
        case type
        when OpenTracing::Reference::CHILD_OF
          Jaeger::Thrift::SpanRefType::CHILD_OF
        when OpenTracing::Reference::FOLLOWS_FROM
          Jaeger::Thrift::SpanRefType::FOLLOWS_FROM
        else
          warn "Jaeger::Client with format #{type} is not supported yet"
          nil
        end
      end

      def prepare_tags(tags)
        with_default_tags = tags.dup
        with_default_tags['jaeger.version'] = 'Ruby-' + Jaeger::Client::VERSION
        with_default_tags['hostname'] ||= Socket.gethostname

        unless with_default_tags['ip']
          ipv4 = Socket.ip_address_list.find { |ai| ai.ipv4? && !ai.ipv4_loopback? }
          with_default_tags['ip'] = ipv4.ip_address unless ipv4.nil?
        end

        with_default_tags.map do |key, value|
          ThriftTagBuilder.build(key, value)
        end
      end

      class DummyTransport
        attr_accessor :size
        def initialize
          @size = 0
        end
        def write(buf)
          @size += buf.size
        end
        def flush; end
        def close; end
      end

      def span_byte_length(span, protocol_class)
        transport = DummyTransport.new
        protocol = protocol_class.new(transport)
        span.write(protocol)
        transport.size
      end
    end
  end
end
