require "json"
require "parslet"
require "set"
require "singleton"
require "forwardable"

module GraphQL
  class ParseError < StandardError
    attr_reader :line, :col, :query
    def initialize(message, line, col, query)
      super(message)
      @line = line
      @col = col
      @query = query
    end
  end

  # Turn a query string into an AST
  # @param string [String] a GraphQL query string
  # @param as [Symbol] If you want to use this to parse some _piece_ of a document, pass the rule name (from {GraphQL::Parser})
  # @return [GraphQL::Language::Nodes::Document]
  def self.parse(string, as: nil)
    parser = as ? GraphQL::PARSER.send(as) : GraphQL::PARSER
    tree = parser.parse(string)
    document = GraphQL::TRANSFORM.apply(tree)
    if !document.is_a?(GraphQL::Language::Nodes::Document)
      raise("Parse failed! Sorry, somehow we failed to turn this string into a document. Please report this bug!")
    end
    document
  rescue Parslet::ParseFailed => error
    line, col = error.cause.source.line_and_column(error.cause.pos)
    raise GraphQL::ParseError.new(error.message, line, col, string)
  end
end

# Order matters for these:

require 'graphql/definition_helpers'
require 'graphql/base_type'
require 'graphql/object_type'

require 'graphql/enum_type'
require 'graphql/input_object_type'
require 'graphql/interface_type'
require 'graphql/list_type'
require 'graphql/non_null_type'
require 'graphql/union_type'

require 'graphql/argument'
require 'graphql/field'
require 'graphql/type_kinds'

require 'graphql/scalar_type'
require 'graphql/boolean_type'
require 'graphql/float_type'
require 'graphql/id_type'
require 'graphql/int_type'
require 'graphql/string_type'

require 'graphql/introspection'
require 'graphql/language'
require 'graphql/directive'
require 'graphql/schema'
require 'graphql/schema/printer'

# Order does not matter for these:

require 'graphql/execution_error'
require 'graphql/query'
require 'graphql/repl'
require 'graphql/static_validation'
require 'graphql/version'
