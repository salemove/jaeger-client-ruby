# frozen_string_literal: true

module Jaeger
  class Span
    class ThriftLogBuilder
      FIELDS = Jaeger::Thrift::Log::FIELDS
      TIMESTAMP = FIELDS[Jaeger::Thrift::Log::TIMESTAMP].fetch(:name)
      LOG_FIELDS = FIELDS[Jaeger::Thrift::Log::LOG_FIELDS].fetch(:name)

      def self.build(timestamp, fields)
        Jaeger::Thrift::Log.new(
          TIMESTAMP => (timestamp.to_f * 1_000_000).to_i,
          LOG_FIELDS => fields.map { |key, value| ThriftTagBuilder.build(key, value) }
        )
      end
    end
  end
end
