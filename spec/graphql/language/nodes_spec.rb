# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Language::Nodes::AbstractNode do
  describe "child and scalar attributes" do
    it "are inherited by node subclasses" do
      subclassed_directive = Class.new(GraphQL::Language::Nodes::Directive)

      assert_equal GraphQL::Language::Nodes::Directive.scalar_attributes,
        subclassed_directive.scalar_attributes

      assert_equal GraphQL::Language::Nodes::Directive.child_attributes,
        subclassed_directive.child_attributes
    end
  end

  describe "#filename" do
    it "is set after .parse_file" do
      filename = "spec/support/parser/filename_example.graphql"
      doc = GraphQL.parse_file(filename)
      op = doc.definitions.first
      field = op.selections.first
      arg = field.arguments.first

      assert_equal filename, doc.filename
      assert_equal filename, op.filename
      assert_equal filename, field.filename
      assert_equal filename, arg.filename
    end

    it "is null when parse from string" do
      doc = GraphQL.parse("{ thing }")
      assert_nil doc.filename
    end
  end

  describe "#to_query_tring" do
    let(:document) {
      GraphQL.parse('type Query { a: String! }')
    }

    class CustomPrinter < GraphQL::Language::Printer
      def print_field_definition(print_field_definition)
        "<Field Hidden>"
      end
    end

    it "accepts a custom printer" do
      expected = <<-SCHEMA
type Query {
  <Field Hidden>
}
      SCHEMA
      assert_equal expected.chomp, document.to_query_string(printer: CustomPrinter)
    end
  end
end
