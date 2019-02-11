# frozen_string_literal: true

module GraphQL
  module Types
    class Int < GraphQL::Schema::Scalar
      description "Represents non-fractional signed whole numeric values. Int can represent values between -(2^31) and 2^31 - 1."

      MIN = -(2**31)
      MAX = (2**31) - 1

      def self.coerce_input(value, _ctx)
        value.is_a?(Numeric) ? value.to_i : nil
      end

      def self.coerce_result(value, ctx)
        value = value.to_i
        ctx.schema.type_error(GraphQL::IntegerEncodingError.new, ctx) unless value.between?(MIN, MAX)
        value
      end

      default_scalar true
    end
  end
end
