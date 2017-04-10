# frozen_string_literal: true
module GraphQL
  # # GraphQL::ScalarType
  #
  # Scalars are plain values. They are leaf nodes in a GraphQL query tree.
  #
  # ## Built-in Scalars
  #
  # `GraphQL` comes with standard built-in scalars:
  #
  # |Constant | `.define` helper|
  # |-------|--------|
  # |`GraphQL::STRING_TYPE` | `types.String`|
  # |`GraphQL::INT_TYPE` | `types.Int`|
  # |`GraphQL::FLOAT_TYPE` | `types.Float`|
  # |`GraphQL::ID_TYPE` | `types.ID`|
  # |`GraphQL::BOOLEAN_TYPE` | `types.Boolean`|
  #
  # (`types` is an instance of `GraphQL::Definition::TypeDefiner`; `.String`, `.Float`, etc are methods which return built-in scalars.)
  #
  # ## Custom Scalars
  #
  # You can define custom scalars for your GraphQL server. It requires some special functions:
  #
  # - `coerce_input` is used to prepare incoming values for GraphQL execution. (Incoming values come from variables or literal values in the query string.)
  # - `coerce_result` is used to turn Ruby values _back_ into serializable values for query responses.
  #
  # @example defining a type for Time
  #   TimeType = GraphQL::ScalarType.define do
  #     name "Time"
  #     description "Time since epoch in seconds"
  #
  #     coerce_input ->(value, ctx) { Time.at(Float(value)) }
  #     coerce_result ->(value, ctx) { value.to_f }
  #   end
  #
  class ScalarType < GraphQL::BaseType
    accepts_definitions :coerce, :coerce_input, :coerce_result
    ensure_defined :coerce_non_null_input, :coerce_result

    module NoOpCoerce
      def self.call(val, ctx)
        val
      end
    end

    def initialize
      super
      self.coerce = NoOpCoerce
    end

    def coerce=(proc)
      self.coerce_input = proc
      self.coerce_result = proc
    end

    def coerce_input=(coerce_input_fn)
      if !coerce_input_fn.nil?
        @coerce_input_proc = ensure_two_arg(coerce_input_fn, :coerce_input)
      end
    end

    def coerce_result(value, ctx = nil)
      if ctx.nil?
        warn_deprecated_coerce("coerce_isolated_result")
        ctx = GraphQL::Query::NullContext
      end
      @coerce_result_proc.call(value, ctx)
    end

    def coerce_result=(coerce_result_fn)
      if !coerce_result_fn.nil?
        @coerce_result_proc = ensure_two_arg(coerce_result_fn, :coerce_result)
      end
    end

    def kind
      GraphQL::TypeKinds::SCALAR
    end

    private

    def get_arity(callable)
      case callable
      when Proc
        callable.arity
      else
        callable.method(:call).arity
      end
    end

    def ensure_two_arg(callable, method_name)
      if get_arity(callable) == 1
        warn("Scalar coerce functions receive two values (`val` and `ctx`), one-argument functions are deprecated (see #{name}.#{method_name}).")
        ->(val, ctx) { callable.call(val) }
      else
        callable
      end
    end

    def coerce_non_null_input(value, ctx)
      @coerce_input_proc.call(value, ctx)
    end

    def validate_non_null_input(value, ctx)
      result = Query::InputValidationResult.new
      if coerce_non_null_input(value, ctx).nil?
        result.add_problem("Could not coerce value #{GraphQL::Language.serialize(value)} to #{name}")
      end
      result
    end
  end
end
