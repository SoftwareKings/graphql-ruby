# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema do
  let(:schema) { Dummy::Schema }
  let(:admin_schema) { Dummy::AdminSchema }
  let(:relay_schema)  { StarWars::Schema }
  let(:empty_schema) { Class.new(GraphQL::Schema) }

  describe "#find" do
    it "finds a member using a string path" do
      field = schema.find("Edible.fatContent")
      assert_equal "fatContent", field.name
    end
  end

  describe "#union_memberships" do
    it "returns a list of unions that include the type" do
      assert_equal [schema.types["Animal"], schema.types["AnimalAsCow"]], schema.union_memberships(schema.types["Cow"])
    end
  end

  describe "#to_document" do
    it "returns the AST for the schema IDL" do
      expected = GraphQL::Language::DocumentFromSchemaDefinition.new(schema).document
      assert_equal expected.to_query_string, schema.to_document.to_query_string
    end
  end

  describe "#root_types" do
    it "returns a list of the schema's root types" do
      assert_equal(
        [
          Dummy::DairyAppQuery,
          Dummy::DairyAppMutation,
          Dummy::Subscription
        ],
        schema.root_types
      )
    end
  end

  describe "#references_to" do
    it "returns a list of Field and Arguments of that type" do
      cow_field = schema.get_field("Query", "cow")
      assert_equal [cow_field], schema.references_to("Cow")
    end

    it "returns an empty list when type is not referenced by any field or argument" do
      assert_equal [], schema.references_to("Goat")
    end
  end

  describe "#to_definition" do
    it "prints out the schema definition" do
      assert_equal schema.to_definition, GraphQL::Schema::Printer.print_schema(schema)
    end
  end

  # Interpreter has subscription support hardcoded, it doesn't just call through.
  if !TESTING_INTERPRETER
    describe "#subscription" do
      it "calls fields on the subscription type" do
        res = schema.execute("subscription { test }")
        assert_equal("Test", res["data"]["test"])
      end
    end
  end

  describe "#resolve_type" do
    describe "when the return value is nil" do
      it "returns nil" do
        result = relay_schema.resolve_type(123, nil, GraphQL::Query::NullContext)
        assert_equal(nil, result)
      end
    end

    describe "when the return value is not a BaseType" do
      it "raises an error " do
        err = assert_raises(RuntimeError) {
          relay_schema.resolve_type(nil, :test_error, GraphQL::Query::NullContext)
        }
        assert_includes err.message, "not_a_type (Symbol)"
      end
    end

    describe "when the hook wasn't implemented" do
      it "raises not implemented" do
        assert_raises(GraphQL::RequiredImplementationMissingError) {
          empty_schema.resolve_type(Class.new(GraphQL::Schema::Union), nil, nil)
        }
      end
    end
  end

  describe "#disable_introspection_entry_points" do
    it "enables entry points by default" do
      refute_empty empty_schema.introspection_system.entry_points
    end

    describe "when disable_introspection_entry_points is configured" do
      let(:schema) do
        Class.new(GraphQL::Schema) do
          disable_introspection_entry_points
        end
      end

      it "clears entry points" do
        assert_empty schema.introspection_system.entry_points
      end
    end
  end

  describe "object_from_id" do
    describe "when the hook wasn't implemented" do
      it "raises not implemented" do
        assert_raises(GraphQL::RequiredImplementationMissingError) {
          empty_schema.object_from_id(nil, nil)
        }
      end
    end
  end

  describe "id_from_object" do
    describe "when the hook wasn't implemented" do
      it "raises not implemented" do
        assert_raises(GraphQL::RequiredImplementationMissingError) {
          empty_schema.id_from_object(nil, nil, nil)
        }
      end
    end

    describe "when a schema is defined with a node field, but no hook" do
      it "raises not implemented" do
        query_type = Class.new(GraphQL::Schema::Object) do
          graphql_name "Query"
          add_field(GraphQL::Types::Relay::NodeField)
        end

        thing_type = Class.new(GraphQL::Schema::Object) do
          graphql_name "Thing"
          implements GraphQL::Types::Relay::Node
        end

        schema = Class.new(GraphQL::Schema) {
          query(query_type)
          orphan_types(thing_type)
        }

        assert_raises(GraphQL::RequiredImplementationMissingError) {
          schema.execute("{ node(id: \"1\") { id } }")
        }
      end
    end
  end

  describe "directives" do
    describe "when directives are not overwritten" do
      it "contains built-in directives" do
        schema = GraphQL::Schema

        assert_equal ['deprecated', 'include', 'skip'], schema.directives.keys.sort

        assert_equal GraphQL::Schema::Directive::Deprecated, schema.directives['deprecated']
        assert_equal GraphQL::Schema::Directive::Include, schema.directives['include']
        assert_equal GraphQL::Schema::Directive::Skip, schema.directives['skip']
      end
    end
  end

  describe ".from_definition" do
    it "uses BuildFromSchema to build a schema from a definition string" do
      schema = <<-SCHEMA
type Query {
  str: String
}
      SCHEMA

      built_schema = GraphQL::Schema.from_definition(schema)
      assert_equal schema.chop, GraphQL::Schema::Printer.print_schema(built_schema)
    end

    it "builds from a file" do
      schema = GraphQL::Schema.from_definition("spec/support/magic_cards/schema.graphql")
      assert_instance_of Class, schema
      expected_types =  ["Card", "Color", "Expansion", "Printing"]
      assert_equal expected_types, (expected_types & schema.types.keys)
    end
  end

  describe ".from_introspection" do
    let(:schema) {

      query_root = Class.new(GraphQL::Schema::Object) do
        graphql_name 'Query'
        field :str, String, null: true
      end

      Class.new(GraphQL::Schema) do
        query query_root
      end
    }
    let(:schema_json) {
      schema.execute(GraphQL::Introspection::INTROSPECTION_QUERY)
    }
    it "uses Schema::Loader to build a schema from an introspection result" do
      built_schema = GraphQL::Schema.from_introspection(schema_json)
      assert_equal GraphQL::Schema::Printer.print_schema(schema), GraphQL::Schema::Printer.print_schema(built_schema)
    end
  end

  describe "#instrument" do
    class VariableCountInstrumenter
      attr_reader :counts
      def initialize
        @counts = []
      end

      def before_query(query)
        @counts << query.variables.length
      end

      def after_query(query)
        @counts << :end
      end
    end

    # Use this to assert instrumenters are called as a stack
    class StackCheckInstrumenter
      def initialize(counter)
        @counter = counter
      end

      def before_query(query)
        @counter.counts << :in
      end

      def after_query(query)
        @counter.counts << :out
      end
    end

    let(:variable_counter) {
      VariableCountInstrumenter.new
    }

    let(:schema) {
      spec = self
      Class.new(GraphQL::Schema) do
        query_type = Class.new(GraphQL::Schema::Object) do
          graphql_name "Query"
          field :int, Integer, null: true do
            argument :value, Integer, required: false
          end

          def int(value:)
            value == 13 ? raise("13 is unlucky") : value
          end
        end

        query(query_type)
        instrument(:query, StackCheckInstrumenter.new(spec.variable_counter))
        instrument(:query, spec.variable_counter)
      end
    }

    it "can wrap query execution" do
      schema.execute("query getInt($val: Int = 5){ int(value: $val) } ")
      schema.execute("query getInt($val: Int = 5, $val2: Int = 3){ int(value: $val) int2: int(value: $val2) } ")
      assert_equal [:in, 1, :end, :out, :in, 2, :end, :out], variable_counter.counts
    end

    it "runs even when a runtime error occurs" do
      schema.execute("query getInt($val: Int = 5){ int(value: $val) } ")
      assert_raises(RuntimeError) {
        schema.execute("query getInt($val: Int = 13){ int(value: $val) } ")
      }
      assert_equal [:in, 1, :end, :out, :in, 1, :end, :out], variable_counter.counts
    end
  end

  describe "#lazy? / #lazy_method_name" do
    class LazyObj; end
    class LazyObjChild < LazyObj; end

    let(:schema) {
      query_type = Class.new(GraphQL::Schema::Object) do
        graphql_name "Query"
      end

      Class.new(GraphQL::Schema) do
        query(query_type)
        lazy_resolve(Integer, :itself)
        lazy_resolve(LazyObj, :dup)
      end
    }

    it "returns registered lazy method names by class/superclass, or returns nil" do
      assert_equal :itself, schema.lazy_method_name(68)
      assert_equal true, schema.lazy?(77)
      assert_equal :dup, schema.lazy_method_name(LazyObj.new)
      assert_equal true, schema.lazy?(LazyObj.new)
      assert_equal :dup, schema.lazy_method_name(LazyObjChild.new)
      assert_equal true, schema.lazy?(LazyObjChild.new)
      assert_nil schema.lazy_method_name({})
      assert_equal false, schema.lazy?({})
    end
  end


  describe "#validate" do
    it "returns errors on the query string" do
      errors = schema.validate("{ cheese(id: 1) { flavor flavor: id } }")
      assert_equal 1, errors.length
      assert_equal "Field 'flavor' has a field conflict: flavor or id?", errors.first.message

      errors = schema.validate("{ cheese(id: 1) { flavor id } }")
      assert_equal [], errors
    end

    it "accepts a list of custom rules" do
      custom_rules = GraphQL::StaticValidation::ALL_RULES - [GraphQL::StaticValidation::FragmentsAreNamed]
      errors = schema.validate("fragment on Cheese { id }", rules: custom_rules)
      assert_equal([], errors)
    end

    it "accepts a context hash" do
      context = { admin: false }
      # AdminSchema is a barebones dummy schema, where fields are visible only with context[:admin] == true
      errors = admin_schema.validate('query { adminOnlyMessage }', context: context)
      assert_equal 1, errors.length
      assert_equal("Field 'adminOnlyMessage' doesn't exist on type 'AdminDairyAppQuery'", errors.first.message)

      context = { admin: true }
      errors = admin_schema.validate('query { adminOnlyMessage }', context: context)
      assert_equal([], errors)
    end
  end

  describe "#as_json / #to_json" do
    it "returns the instrospection result" do
      result = schema.execute(GraphQL::Introspection::INTROSPECTION_QUERY)
      assert_equal result, schema.as_json
      assert_equal result, JSON.parse(schema.to_json)
    end
  end

  describe "#as_json" do
    it "returns a hash" do
      result = schema.execute(GraphQL::Introspection::INTROSPECTION_QUERY)
      assert_equal result.as_json.class, Hash
    end
  end

  describe "#get_field" do
    it "returns fields by type or type name" do
      field = schema.get_field("Cheese", "id")
      assert_instance_of Dummy::BaseField, field
      field_2 = schema.get_field(Dummy::Cheese, "id")
      assert_equal field, field_2
    end
  end

  describe "class-based schemas" do
    it "implements methods" do
      # Not delegated:
      assert_equal Jazz::Query, Jazz::Schema.query
      assert Jazz::Schema.respond_to?(:query)
      # Delegated
      assert_equal [], Jazz::Schema.tracers
      assert Jazz::Schema.respond_to?(:tracers)
    end

    it "works with plugins" do
      assert_equal "xyz", Jazz::Schema.metadata[:plugin_key]
    end
  end
end
