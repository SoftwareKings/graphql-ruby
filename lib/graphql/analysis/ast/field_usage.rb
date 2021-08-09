# frozen_string_literal: true
module GraphQL
  module Analysis
    module AST
      class FieldUsage < Analyzer
        def initialize(query)
          super
          @used_fields = Set.new
          @used_deprecated_fields = Set.new
          @used_deprecated_arguments = Set.new
        end

        def on_leave_field(node, parent, visitor)
          field_defn = visitor.field_definition
          field = "#{visitor.parent_type_definition.graphql_name}.#{field_defn.graphql_name}"
          @used_fields << field
          @used_deprecated_fields << field if field_defn.deprecation_reason

          extract_deprecated_arguments(visitor.query.arguments_for(node, visitor.field_definition).argument_values)
        end

        def result
          {
            used_fields: @used_fields.to_a,
            used_deprecated_fields: @used_deprecated_fields.to_a,
            used_deprecated_arguments: @used_deprecated_arguments.to_a,
          }
        end

        private

        def extract_deprecated_arguments(argument_values)
          argument_values.each_pair do |_argument_name, argument|
            if argument.definition.deprecation_reason
              @used_deprecated_arguments << argument.definition.path
            end

            if argument.definition.type.kind.input_object?
              extract_deprecated_arguments(argument.value.arguments.argument_values)
            elsif argument.definition.type.list?
              argument
                .value
                .select { |value| value.respond_to?(:arguments) }
                .each { |value| extract_deprecated_arguments(value.arguments.argument_values) }
            end
          end
        end
      end
    end
  end
end
