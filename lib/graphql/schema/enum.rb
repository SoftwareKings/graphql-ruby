# frozen_string_literal: true

module GraphQL
  # Extend this class to define GraphQL enums in your schema.
  #
  # By default, GraphQL enum values are translated into Ruby strings.
  # You can provide a custom value with the `value:` keyword.
  #
  # @example
  #   # equivalent to
  #   # enum PizzaTopping {
  #   #   MUSHROOMS
  #   #   ONIONS
  #   #   PEPPERS
  #   # }
  #   class PizzaTopping < GraphQL::Enum
  #     value :MUSHROOMS
  #     value :ONIONS
  #     value :PEPPERS
  #   end
  class Schema
    class Enum < GraphQL::Schema::Member
      extend GraphQL::Schema::Member::AcceptsDefinition
      extend GraphQL::Schema::Member::ValidatesInput

      class UnresolvedValueError < GraphQL::EnumType::UnresolvedValueError
        def initialize(value:, enum:, context:)
          fix_message = ", but this isn't a valid value for `#{enum.graphql_name}`. Update the field or resolver to return one of `#{enum.graphql_name}`'s values instead."
          message = if (cp = context[:current_path]) && (cf = context[:current_field])
            "`#{cf.path}` returned `#{value.inspect}` at `#{cp.join(".")}`#{fix_message}"
          else
            "`#{value.inspect}` was returned for `#{enum.graphql_name}`#{fix_message}"
          end
          super(message)
        end
      end

      class << self
        # Define a value for this enum
        # @param graphql_name [String, Symbol] the GraphQL value for this, usually `SCREAMING_CASE`
        # @param description [String], the GraphQL description for this value, present in documentation
        # @param value [Object], the translated Ruby value for this object (defaults to `graphql_name`)
        # @param deprecation_reason [String] if this object is deprecated, include a message here
        # @return [void]
        # @see {Schema::EnumValue} which handles these inputs by default
        def value(*args, **kwargs, &block)
          kwargs[:owner] = self
          value = enum_value_class.new(*args, **kwargs, &block)
          key = value.graphql_name
          prev_value = own_values[key]
          case prev_value
          when nil
            own_values[key] = value
          when GraphQL::Schema::EnumValue
            own_values[key] = [prev_value, value]
          when Array
            prev_value << value
          else
            raise "Invariant: Unexpected enum value for #{key.inspect}: #{prev_value.inspect}"
          end
          nil
        end

        # @return [Array<GraphQL::Schema::EnumValue>] Possible values of this enum
        def enum_values(context = GraphQL::Query::NullContext)
          inherited_values = superclass.respond_to?(:enum_values) ? superclass.enum_values(context) : nil
          visible_values = []
          warden = Warden.from_context(context)
          own_values.each do |key, values_entry|
            if (v = Warden.visible_entry?(:visible_enum_value?, values_entry, context, warden))
              visible_values << v
            end
          end

          if inherited_values
            # Local values take precedence over inherited ones
            inherited_values.each do |i_val|
              if !visible_values.any? { |v| v.graphql_name == i_val.graphql_name }
                visible_values << i_val
              end
            end
          end

          visible_values
        end

        # @return [Hash<String => GraphQL::Schema::EnumValue>] Possible values of this enum, keyed by name.
        def values(context = GraphQL::Query::NullContext)
          enum_values(context).each_with_object({}) { |val, obj| obj[val.graphql_name] = val }
        end

        # @return [GraphQL::EnumType]
        def to_graphql
          enum_type = GraphQL::EnumType.new
          enum_type.name = graphql_name
          enum_type.description = description
          enum_type.introspection = introspection
          enum_type.ast_node = ast_node
          values.each do |name, val|
            enum_type.add_value(val.to_graphql)
          end
          enum_type.metadata[:type_class] = self
          enum_type
        end

        # @return [Class] for handling `value(...)` inputs and building `GraphQL::Enum::EnumValue`s out of them
        def enum_value_class(new_enum_value_class = nil)
          if new_enum_value_class
            @enum_value_class = new_enum_value_class
          elsif defined?(@enum_value_class) && @enum_value_class
            @enum_value_class
          else
            superclass <= GraphQL::Schema::Enum ? superclass.enum_value_class : nil
          end
        end

        def kind
          GraphQL::TypeKinds::ENUM
        end

        def validate_non_null_input(value_name, ctx)
          result = GraphQL::Query::InputValidationResult.new

          allowed_values = ctx.warden.enum_values(self)
          matching_value = allowed_values.find { |v| v.graphql_name == value_name }

          if matching_value.nil?
            result.add_problem("Expected #{GraphQL::Language.serialize(value_name)} to be one of: #{allowed_values.map(&:graphql_name).join(', ')}")
          end

          result
        end

        def coerce_result(value, ctx)
          warden = ctx.warden
          all_values = warden ? warden.enum_values(self) : values.each_value
          enum_value = all_values.find { |val| val.value == value }
          if enum_value
            enum_value.graphql_name
          else
            raise self::UnresolvedValueError.new(enum: self, value: value, context: ctx)
          end
        end

        def coerce_input(value_name, ctx)
          all_values = ctx.warden ? ctx.warden.enum_values(self) : values.each_value

          if v = all_values.find { |val| val.graphql_name == value_name }
            v.value
          elsif v = all_values.find { |val| val.value == value_name }
            # this is for matching default values, which are "inputs", but they're
            # the Ruby value, not the GraphQL string.
            v.value
          else
            nil
          end
        end

        def inherited(child_class)
          child_class.const_set(:UnresolvedValueError, Class.new(Schema::Enum::UnresolvedValueError))
          super
        end

        private

        def own_values
          @own_values ||= {}
        end
      end

      enum_value_class(GraphQL::Schema::EnumValue)
    end
  end
end
