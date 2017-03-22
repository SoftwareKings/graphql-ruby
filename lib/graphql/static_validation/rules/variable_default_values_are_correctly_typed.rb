# frozen_string_literal: true
module GraphQL
  module StaticValidation
    class VariableDefaultValuesAreCorrectlyTyped
      include GraphQL::StaticValidation::Message::MessageHelper

      def validate(context)
        context.visitor[GraphQL::Language::Nodes::VariableDefinition] << ->(node, parent) {
          if !node.default_value.nil?
            validate_default_value(node, context)
          end
        }
      end

      def validate_default_value(node, context)
        value = node.default_value
        if node.type.is_a?(GraphQL::Language::Nodes::NonNullType)
          context.errors << message("Non-null variable $#{node.name} can't have a default value", node, context: context)
        else
          type = context.schema.type_from_ast(node.type)
          if type.nil?
            # This is handled by another validator
          elsif !context.valid_literal?(value, type)
            context.errors << message("Default value for $#{node.name} doesn't match type #{type}", node, context: context)
          end
        end
      end
    end
  end
end
