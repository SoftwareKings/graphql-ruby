# frozen_string_literal: true
module GraphQL
  module StaticValidation
    # Initialized with a {GraphQL::Schema}, then it can validate {GraphQL::Language::Nodes::Documents}s based on that schema.
    #
    # By default, it's used by {GraphQL::Query}
    #
    # @example Validate a query
    #   validator = GraphQL::StaticValidation::Validator.new(schema: MySchema)
    #   query = GraphQL::Query.new(MySchema, query_string)
    #   errors = validator.validate(query)[:errors]
    #
    class Validator
      # @param schema [GraphQL::Schema]
      # @param rules [Array<#validate(context)>] a list of rules to use when validating
      def initialize(schema:, rules: GraphQL::StaticValidation::ALL_RULES)
        @schema = schema
        @rules = rules
      end

      # Validate `query` against the schema. Returns an array of message hashes.
      # @param query [GraphQL::Query]
      # @return [Array<Hash>]
      def validate(query, validate: true)
        query.trace("validate", { validate: validate, query: query }) do

          rules_to_use = validate ? @rules : []
          can_skip_rewrite = query.context.interpreter? && query.schema.using_ast_analysis?
          visitor_class = BaseVisitor.including_rules(rules_to_use, rewrite: !can_skip_rewrite)

          context = GraphQL::StaticValidation::ValidationContext.new(query, visitor_class)

          # Attach legacy-style rules
          rules_to_use.each do |rule_class_or_module|
            if rule_class_or_module.method_defined?(:validate)
              rule_class_or_module.new.validate(context)
            end
          end

          context.visitor.visit
          rewrite_result = can_skip_rewrite ? nil : context.visitor.rewrite_document

          {
            errors: context.errors,
            # If there were errors, the irep is garbage
            irep: context.errors.any? ? nil : rewrite_result,
          }
        end
      end
    end
  end
end
