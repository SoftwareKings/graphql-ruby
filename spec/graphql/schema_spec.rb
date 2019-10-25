# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema do
  describe "inheritance" do
    class DummyFeature1 < GraphQL::Schema::Directive::Feature

    end

    class DummyFeature2 < GraphQL::Schema::Directive::Feature

    end

    class Query < GraphQL::Schema::Object
      field :some_field, String, null: true
    end

    class Mutation < GraphQL::Schema::Object
      field :some_field, String, null: true
    end

    class Subscription < GraphQL::Schema::Object
      field :some_field, String, null: true
    end

    let(:base_schema) do
      Class.new(GraphQL::Schema) do
        query Query
        mutation Mutation
        subscription Subscription
        max_complexity 1
        max_depth 2
        default_max_page_size 3
        error_bubbling false
        disable_introspection_entry_points
        orphan_types Jazz::Ensemble
        introspection Module.new
        cursor_encoder Object.new
        query_execution_strategy Object.new
        mutation_execution_strategy Object.new
        subscription_execution_strategy Object.new
        context_class Class.new
        directives [DummyFeature1]
        tracer GraphQL::Tracing::DataDogTracing
        query_analyzer Object.new
        multiplex_analyzer Object.new
        rescue_from(StandardError) { }
        instrument :field, GraphQL::Relay::EdgesInstrumentation
        middleware (Proc.new {})
        use GraphQL::Backtrace
      end
    end

    it "inherits configuration from its superclass" do
      schema = Class.new(base_schema)
      assert_equal base_schema.query, schema.query
      assert_equal base_schema.mutation, schema.mutation
      assert_equal base_schema.subscription, schema.subscription
      assert_equal base_schema.introspection, schema.introspection
      assert_equal base_schema.cursor_encoder, schema.cursor_encoder
      assert_equal base_schema.query_execution_strategy, schema.query_execution_strategy
      assert_equal base_schema.mutation_execution_strategy, schema.mutation_execution_strategy
      assert_equal base_schema.subscription_execution_strategy, schema.subscription_execution_strategy
      assert_equal base_schema.max_complexity, schema.max_complexity
      assert_equal base_schema.max_depth, schema.max_depth
      assert_equal base_schema.default_max_page_size, schema.default_max_page_size
      assert_equal base_schema.error_bubbling, schema.error_bubbling
      assert_equal base_schema.orphan_types, schema.orphan_types
      assert_equal base_schema.context_class, schema.context_class
      assert_equal base_schema.directives, schema.directives
      assert_equal base_schema.tracers, schema.tracers
      assert_equal base_schema.query_analyzers, schema.query_analyzers
      assert_equal base_schema.multiplex_analyzers, schema.multiplex_analyzers
      assert_equal base_schema.rescues, schema.rescues
      assert_equal base_schema.instrumenters, schema.instrumenters
      assert_equal base_schema.middleware.steps.size, schema.middleware.steps.size
      assert_equal base_schema.disable_introspection_entry_points?, schema.disable_introspection_entry_points?
      assert_equal [GraphQL::Backtrace], schema.plugins.map(&:first)
    end

    it "can override configuration from its superclass" do
      schema = Class.new(base_schema)
      query = Class.new(GraphQL::Schema::Object) do
        graphql_name 'Query'
        field :some_field, String, null: true
      end
      schema.query(query)
      mutation = Class.new(GraphQL::Schema::Object) do
        graphql_name 'Mutation'
        field :some_field, String, null: true
      end
      schema.mutation(mutation)
      subscription = Class.new(GraphQL::Schema::Object) do
        graphql_name 'Subscription'
        field :some_field, String, null: true
      end
      schema.subscription(subscription)
      introspection = Module.new
      schema.introspection(introspection)
      cursor_encoder = Object.new
      schema.cursor_encoder(cursor_encoder)
      query_execution_strategy = Object.new
      schema.query_execution_strategy(query_execution_strategy)
      mutation_execution_strategy = Object.new
      schema.mutation_execution_strategy(mutation_execution_strategy)
      subscription_execution_strategy = Object.new
      schema.subscription_execution_strategy(subscription_execution_strategy)
      # Assert these _before_ `use(Interpreter)` below
      assert_equal query_execution_strategy, schema.query_execution_strategy
      assert_equal mutation_execution_strategy, schema.mutation_execution_strategy
      assert_equal subscription_execution_strategy, schema.subscription_execution_strategy

      context_class = Class.new
      schema.context_class(context_class)
      schema.max_complexity(10)
      schema.max_depth(20)
      schema.default_max_page_size(30)
      schema.error_bubbling(true)
      schema.orphan_types(Jazz::InstrumentType)
      schema.directives([DummyFeature2])
      query_analyzer = Object.new
      schema.query_analyzer(query_analyzer)
      multiplex_analyzer = Object.new
      schema.multiplex_analyzer(multiplex_analyzer)
      schema.use(GraphQL::Execution::Interpreter)
      schema.instrument(:field, GraphQL::Relay::ConnectionInstrumentation)
      schema.rescue_from(GraphQL::ExecutionError)
      schema.tracer(GraphQL::Tracing::NewRelicTracing)
      schema.middleware(Proc.new {})

      assert_equal query, schema.query
      assert_equal mutation, schema.mutation
      assert_equal subscription, schema.subscription
      assert_equal introspection, schema.introspection
      assert_equal cursor_encoder, schema.cursor_encoder

      assert_equal context_class, schema.context_class
      assert_equal 10, schema.max_complexity
      assert_equal 20, schema.max_depth
      assert_equal 30, schema.default_max_page_size
      assert schema.error_bubbling
      assert_equal [Jazz::Ensemble, Jazz::InstrumentType], schema.orphan_types
      assert_equal schema.directives, GraphQL::Schema.default_directives.merge(DummyFeature1.graphql_name => DummyFeature1, DummyFeature2.graphql_name => DummyFeature2)
      assert_equal base_schema.query_analyzers + [query_analyzer], schema.query_analyzers
      assert_equal base_schema.multiplex_analyzers + [multiplex_analyzer], schema.multiplex_analyzers
      assert_equal [GraphQL::Backtrace, GraphQL::Execution::Interpreter], schema.plugins.map(&:first)
      assert_equal [GraphQL::Relay::EdgesInstrumentation, GraphQL::Relay::ConnectionInstrumentation], schema.instrumenters[:field]
      assert_equal [GraphQL::ExecutionError, StandardError], schema.rescues.keys.sort_by(&:name)
      assert_equal [GraphQL::Tracing::DataDogTracing, GraphQL::Backtrace::Tracer], base_schema.tracers
      assert_equal [GraphQL::Tracing::DataDogTracing, GraphQL::Backtrace::Tracer, GraphQL::Tracing::NewRelicTracing], schema.tracers
      # This doesn't include `RescueMiddleware`, since interpreter handles that separately.
      assert_equal 2, schema.middleware.steps.size
    end
  end

  describe "merged, inherited caches" do
    METHODS_TO_CACHE = [:types, :possible_types, :union_memberships, :references_to]

    let(:schema) do
      Class.new(Dummy::Schema) do
        def self.reset_calls
          @calls = Hash.new(0)
          @callers = Hash.new { |h, k| h[k] = [] }
        end

        METHODS_TO_CACHE.each do |method_name|
          define_singleton_method(method_name) do |*args, &block|
            if @calls
              call_count = @calls[method_name] += 1
              @callers[method_name] << caller
            else
              call_count = 0
            end
            if call_count > 1
              raise "Called #{method_name} more than once, previous caller: #{@callers[method_name].first}"
            end
            super(*args, &block)
          end
        end
      end
    end

    it "caches #{METHODS_TO_CACHE} at runtime" do
      query_str = "
        query getFlavor($cheeseId: Int!) {
          brie: cheese(id: 1)   { ...cheeseFields, taste: flavor },
          cheese(id: $cheeseId)  {
            __typename,
            id,
            ...cheeseFields,
            ... edibleFields,
            ... on Cheese { cheeseKind: flavor },
          }
          fromSource(source: COW) { id }
          fromSheep: fromSource(source: SHEEP) { id }
          firstSheep: searchDairy(product: [{source: SHEEP}]) {
            __typename,
            ... dairyFields,
            ... milkFields
          }
          favoriteEdible { __typename, fatContent }
        }
        fragment cheeseFields on Cheese { flavor }
        fragment edibleFields on Edible { fatContent }
        fragment milkFields on Milk { source }
        fragment dairyFields on AnimalProduct {
           ... on Cheese { flavor }
           ... on Milk   { source }
        }
      "
      schema.reset_calls
      res = schema.execute(query_str,  variables: { cheeseId: 2 })
      assert_equal "Brie", res["data"]["brie"]["flavor"]
    end
  end

  describe "when mixing define and class-based" do
    module MixedSchema
      class Query < GraphQL::Schema::Object
        field :int, Int, null: false
      end

      class Mutation < GraphQL::Schema::Object
        field :int, Int, null: false
      end

      class Subscription < GraphQL::Schema::Object
        field :int, Int, null: false
      end

      Schema = GraphQL::Schema.define do
        query(Query)
        mutation(Mutation)
        subscription(Subscription)
      end
    end

    it "includes root types properly" do
      res = MixedSchema::Schema.as_json
      assert_equal "Query", res["data"]["__schema"]["queryType"]["name"]
      assert_includes res["data"]["__schema"]["types"].map { |t| t["name"] }, "Query"

      assert_equal "Mutation", res["data"]["__schema"]["mutationType"]["name"]
      assert_includes res["data"]["__schema"]["types"].map { |t| t["name"] }, "Mutation"

      assert_equal "Subscription", res["data"]["__schema"]["subscriptionType"]["name"]
      assert_includes res["data"]["__schema"]["types"].map { |t| t["name"] }, "Subscription"
    end
  end

  describe ".possible_types" do
    it "returns a single item for objects" do
      assert_equal [Dummy::Cheese], Dummy::Schema.possible_types(Dummy::Cheese)
    end

    it "returns empty for abstract types without any possible types" do
      unknown_union = Class.new(GraphQL::Schema::Union) { graphql_name("Unknown") }
      assert_equal [], Dummy::Schema.possible_types(unknown_union)
    end
  end
end
