# frozen_string_literal: true

module Jaeger
  class ThriftTagBuilder
    FIELDS = Jaeger::Thrift::Tag::FIELDS
    KEY = FIELDS[Jaeger::Thrift::Tag::KEY].fetch(:name)
    VTYPE = FIELDS[Jaeger::Thrift::Tag::VTYPE].fetch(:name)
    VLONG = FIELDS[Jaeger::Thrift::Tag::VLONG].fetch(:name)
    VDOUBLE = FIELDS[Jaeger::Thrift::Tag::VDOUBLE].fetch(:name)
    VBOOL = FIELDS[Jaeger::Thrift::Tag::VBOOL].fetch(:name)
    VSTR = FIELDS[Jaeger::Thrift::Tag::VSTR].fetch(:name)

    def self.build(key, value)
      case value
      when Integer
        Jaeger::Thrift::Tag.new(
          KEY => key.to_s,
          VTYPE => Jaeger::Thrift::TagType::LONG,
          VLONG => value
        )
      when Float
        Jaeger::Thrift::Tag.new(
          KEY => key.to_s,
          VTYPE => Jaeger::Thrift::TagType::DOUBLE,
          VDOUBLE => value
        )
      when TrueClass, FalseClass
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
