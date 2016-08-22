require "graphql/schema/catchall_middleware"
require "graphql/schema/invalid_type_error"
require "graphql/schema/middleware_chain"
require "graphql/schema/rescue_middleware"
require "graphql/schema/possible_types"
require "graphql/schema/reduce_types"
require "graphql/schema/timeout_middleware"
require "graphql/schema/type_expression"
require "graphql/schema/type_map"
require "graphql/schema/validation"

module GraphQL
  # A GraphQL schema which may be queried with {GraphQL::Query}.
  #
  # The {Schema} contains:
  #
  #  - types for exposing your application
  #  - query analyzers for assessing incoming queries (including max depth & max complexity restrictions)
  #  - execution strategies for running incoming queries
  #  - middleware for interacting with execution
  #
  # Schemas start with root types, {Schema#query}, {Schema#mutation} and {Schema#subscription}.
  # The schema will traverse the tree of fields & types, using those as starting points.
  # Any undiscoverable types may be provided with the `types` configuration.
  #
  # Schemas can restrict large incoming queries with `max_depth` and `max_complexity` configurations.
  # (These configurations can be overridden by specific calls to {Schema#execute})
  #
  # Schemas can specify how queries should be executed against them.
  # `query_execution_strategy`, `mutation_execution_strategy` and `subscription_execution_strategy`
  # each apply to corresponding root types.
  #
  # A schema accepts a `Relay::GlobalNodeIdentification` instance for use with Relay IDs.
  #
  # @example defining a schema
  #   MySchema = GraphQL::Schema.define do
  #     query QueryType
  #     middleware PermissionMiddleware
  #     rescue_from(ActiveRecord::RecordNotFound) { "Not found" }
  #     # If types are only connected by way of interfaces, they must be added here
  #     orphan_types ImageType, AudioType
  #   end
  #
  class Schema
    include GraphQL::Define::InstanceDefinable
    accepts_definitions \
      :query, :mutation, :subscription,
      :query_execution_strategy, :mutation_execution_strategy, :subscription_execution_strategy,
      :max_depth, :max_complexity,
      :node_identification,
      :orphan_types,
      query_analyzer: -> (schema, analyzer) { schema.query_analyzers << analyzer },
      middleware: -> (schema, middleware) { schema.middleware << middleware },
      rescue_from: -> (schema, err_class, &block) { schema.rescue_from(err_class, &block)}

    lazy_defined_attr_accessor \
      :query, :mutation, :subscription,
      :query_execution_strategy, :mutation_execution_strategy, :subscription_execution_strategy,
      :max_depth, :max_complexity,
      :node_identification,
      :orphan_types,
      :query_analyzers, :middleware


    DIRECTIVES = [GraphQL::Directive::SkipDirective, GraphQL::Directive::IncludeDirective]
    DYNAMIC_FIELDS = ["__type", "__typename", "__schema"]

    attr_reader :directives, :static_validator

    # @return [GraphQL::Relay::GlobalNodeIdentification] the node identification instance for this schema, when using Relay
    def node_identification
      ensure_defined
      @node_identification
    end

    # @return [Array<#call>] Middlewares suitable for MiddlewareChain, applied to fields during execution
    def middleware
      ensure_defined
      @middleware
    end

    # @param query [GraphQL::ObjectType]  the query root for the schema
    # @param mutation [GraphQL::ObjectType] the mutation root for the schema
    # @param subscription [GraphQL::ObjectType] the subscription root for the schema
    # @param max_depth [Integer] maximum query nesting (if it's greater, raise an error)
    # @param types [Array<GraphQL::BaseType>] additional types to include in this schema
    def initialize(query: nil, mutation: nil, subscription: nil, max_depth: nil, max_complexity: nil, types: [])
      if query
        warn("Schema.new is deprecated, use Schema.define instead")
      end
      @query    = query
      @mutation = mutation
      @subscription = subscription
      @max_depth = max_depth
      @max_complexity = max_complexity
      @orphan_types = types
      @directives = DIRECTIVES.reduce({}) { |m, d| m[d.name] = d; m }
      @static_validator = GraphQL::StaticValidation::Validator.new(schema: self)
      @rescue_middleware = GraphQL::Schema::RescueMiddleware.new
      @middleware = [@rescue_middleware]
      @query_analyzers = []
      # Default to the built-in execution strategy:
      @query_execution_strategy = GraphQL::Query::SerialExecution
      @mutation_execution_strategy = GraphQL::Query::SerialExecution
      @subscription_execution_strategy = GraphQL::Query::SerialExecution
    end

    def rescue_from(*args, &block)
      ensure_defined
      @rescue_middleware.rescue_from(*args, &block)
    end

    def remove_handler(*args, &block)
      ensure_defined
      @rescue_middleware.remove_handler(*args, &block)
    end

    # @return [GraphQL::Schema::TypeMap] `{ name => type }` pairs of types in this schema
    def types
      @types ||= begin
        ensure_defined
        all_types = orphan_types + [query, mutation, subscription, GraphQL::Introspection::SchemaType]
        GraphQL::Schema::ReduceTypes.reduce(all_types.compact)
      end
    end

    # Execute a query on itself.
    # See {Query#initialize} for arguments.
    # @return [Hash] query result, ready to be serialized as JSON
    def execute(*args)
      query_obj = GraphQL::Query.new(self, *args)
      query_obj.result
    end

    # Resolve field named `field_name` for type `parent_type`.
    # Handles dynamic fields `__typename`, `__type` and `__schema`, too
    def get_field(parent_type, field_name)
      ensure_defined
      defined_field = parent_type.get_field(field_name)
      if defined_field
        defined_field
      elsif field_name == "__typename"
        GraphQL::Introspection::TypenameField.create(parent_type)
      elsif field_name == "__schema" && parent_type == query
        GraphQL::Introspection::SchemaField.create(self)
      elsif field_name == "__type" && parent_type == query
        GraphQL::Introspection::TypeByNameField.create(self.types)
      else
        nil
      end
    end

    def type_from_ast(ast_node)
      ensure_defined
      GraphQL::Schema::TypeExpression.build_type(self, ast_node)
    end

    # @param type_defn [GraphQL::InterfaceType, GraphQL::UnionType] the type whose members you want to retrieve
    # @return [Array<GraphQL::ObjectType>] types which belong to `type_defn` in this schema
    def possible_types(type_defn)
      ensure_defined
      @interface_possible_types ||= GraphQL::Schema::PossibleTypes.new(self)
      @interface_possible_types.possible_types(type_defn)
    end

    def root_type_for_operation(operation)
      case operation
      when "query"
        query
      when "mutation"
        mutation
      when "subscription"
        subscription
      else
        raise ArgumentError, "unknown operation type: #{operation}"
      end
    end

    def execution_strategy_for_operation(operation)
      case operation
      when "query"
        query_execution_strategy
      when "mutation"
        mutation_execution_strategy
      when "subscription"
        subscription_execution_strategy
      else
        raise ArgumentError, "unknown operation type: #{operation}"
      end
    end
  end
end
