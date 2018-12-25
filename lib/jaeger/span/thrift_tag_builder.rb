# frozen_string_literal: true

module Jaeger
  class Span
    class ThriftTagBuilder
      FIELDS = Jaeger::Thrift::Tag::FIELDS
      KEY = FIELDS[Jaeger::Thrift::Tag::KEY].fetch(:name)
      VTYPE = FIELDS[Jaeger::Thrift::Tag::VTYPE].fetch(:name)
      VLONG = FIELDS[Jaeger::Thrift::Tag::VLONG].fetch(:name)
      VDOUBLE = FIELDS[Jaeger::Thrift::Tag::VDOUBLE].fetch(:name)
      VBOOL = FIELDS[Jaeger::Thrift::Tag::VBOOL].fetch(:name)
      VSTR = FIELDS[Jaeger::Thrift::Tag::VSTR].fetch(:name)

      def self.build(key, value)
        if value.is_a?(Integer)
          Jaeger::Thrift::Tag.new(
            KEY => key.to_s,
            VTYPE => Jaeger::Thrift::TagType::LONG,
            VLONG => value
          )
        elsif value.is_a?(Float)
          Jaeger::Thrift::Tag.new(
            KEY => key.to_s,
            VTYPE => Jaeger::Thrift::TagType::DOUBLE,
            VDOUBLE => value
          )
        elsif value.is_a?(TrueClass) || value.is_a?(FalseClass)
          Jaeger::Thrift::Tag.new(
            KEY => key.to_s,
            VTYPE => Jaeger::Thrift::TagType::BOOL,
            VBOOL => value
          )
        else
          Jaeger::Thrift::Tag.new(
            KEY => key.to_s,
            VTYPE => Jaeger::Thrift::TagType::STRING,
            VSTR => value.to_s
          )
        end
      end
    end
  end
end
