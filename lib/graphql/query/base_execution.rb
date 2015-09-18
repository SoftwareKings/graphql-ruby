require 'graphql/query/base_execution/value_resolution'

module GraphQL
  class Query
    class BaseExecution
      # This is the only required method for an Execution strategy.
      # You could create a custom execution strategy and configure your schema to
      # use that custom strategy instead.
      #
      # @param ast_operation [GraphQL::Language::Nodes::OperationDefinition] The operation definition to run
      # @param root_type [GraphQL::ObjectType] either the query type or the mutation type
      # @param query_obj [GraphQL::Query] the query object for this execution
      # @return [Hash] a spec-compliant GraphQL result, as a hash
      def execute(ast_operation, root_type, query_obj)
        resolver = operation_resolution.new(ast_operation, root_type, query_obj, self)
        resolver.result
      end

      def field_resolution
        self.class::FieldResolution
      end

      def operation_resolution
        self.class::OperationResolution
      end

      def selection_resolution
        self.class::SelectionResolution
      end
    end
  end
end
