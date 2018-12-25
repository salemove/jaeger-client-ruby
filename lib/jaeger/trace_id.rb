# frozen_string_literal: true

module Jaeger
  module TraceId
    MAX_64BIT_SIGNED_INT = (1 << 63) - 1
    MAX_64BIT_UNSIGNED_INT = (1 << 64) - 1
    TRACE_ID_UPPER_BOUND = MAX_64BIT_UNSIGNED_INT + 1

    def self.generate
      rand(TRACE_ID_UPPER_BOUND)
    end

    def self.base16_hex_id_to_uint64(id)
      return nil unless id
      value = id.to_i(16)
      value > MAX_64BIT_UNSIGNED_INT || value < 0 ? 0 : value
    end

    # Thrift defines ID fields as i64, which is signed, therefore we convert
    # large IDs (> 2^63) to negative longs
    def self.uint64_id_to_int64(id)
      id > MAX_64BIT_SIGNED_INT ? id - MAX_64BIT_UNSIGNED_INT - 1 : id
    end

    # Convert an integer id into a 0 padded hex string.
    # If the string is shorter than 16 characters, it will be padded to 16.
    # If it is longer than 16 characters, it is padded to 32.
    def self.to_hex(id)
      hex_str = id.to_s(16)

      # pad the string with '0's to 16 or 32 characters
      if hex_str.length > 16
        hex_str.rjust(32, '0')
      else
        hex_str.rjust(16, '0')
      end
    end
  end
end
