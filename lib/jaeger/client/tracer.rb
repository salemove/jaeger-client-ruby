module Jaeger
  module Client
    class Tracer
      def initialize(client, service_name)
        @client = client
      end

      # Starts a new span.
      #
      # @param operation_name [String] The operation name for the Span
      # @param child_of [SpanContext, Span] SpanContext that acts as a parent to
      #        the newly-started Span. If a Span instance is provided, its
      #        context is automatically substituted.
      # @param start_time [Time] When the Span started, if not now
      # @param tags [Hash] Tags to assign to the Span at start time
      #
      # @return [Span] The newly-started Span
      def start_span(operation_name, child_of: nil, start_time: Time.now, tags: {}, **)
        context =
          if child_of
            parent_context = child_of.respond_to?(:context) ? child_of.context : child_of
            SpanContext.create_from_parent_context(parent_context)
          else
            SpanContext.create_parent_context
          end
        Span.new(context, operation_name, @client, start_time: start_time, tags: tags)
      end

      # Inject a SpanContext into the given carrier
      #
      # @param span_context [SpanContext]
      # @param format [OpenTracing::FORMAT_TEXT_MAP, OpenTracing::FORMAT_BINARY, OpenTracing::FORMAT_RACK]
      # @param carrier [Carrier] A carrier object of the type dictated by the specified `format`
      def inject(span_context, format, carrier)
        case format
        when OpenTracing::FORMAT_TEXT_MAP, OpenTracing::FORMAT_RACK
          carrier['uber-trace-id'] = [
            span_context.trace_id,
            span_context.span_id,
            span_context.parent_id || 0,
            span_context.flags
          ].join(':')
        else
          warn "Jaeger::Client with format #{format} is not supported yet"
        end
      end

      # Extract a SpanContext in the given format from the given carrier.
      #
      # @param format [OpenTracing::FORMAT_TEXT_MAP, OpenTracing::FORMAT_BINARY, OpenTracing::FORMAT_RACK]
      # @param carrier [Carrier] A carrier object of the type dictated by the specified `format`
      # @return [SpanContext] the extracted SpanContext or nil if none could be found
      def extract(format, carrier)
        case format
        when OpenTracing::FORMAT_TEXT_MAP
          parse_context(carrier['uber-trace-id'])
        when OpenTracing::FORMAT_RACK
          parse_context(carrier['HTTP_UBER_TRACE_ID'])
        else
          warn "Jaeger::Client with format #{format} is not supported yet"
          nil
        end
      end

      private

      def parse_context(trace)
        return nil if !trace || trace == ''
        trace_id, span_id, parent_id, _flags = trace.split(':')

        parent_id = parent_id.to_i
        parent_id = nil if parent_id == 0

        trace_id = trace_id.to_i
        span_id = span_id.to_i

        if trace_id != 0 && span_id != 0
          SpanContext.new(trace_id: trace_id, parent_id: parent_id, span_id: span_id)
        else
          nil
        end
      end
    end
  end
end
