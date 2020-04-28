# frozen_string_literal: true

module GraphQL
  module Execution
    class Interpreter
      # A wrapper for argument hashes in GraphQL queries.
      #
      # @see GraphQL::Query#arguments_for to get access to these objects.
      class Arguments
        extend Forwardable
        include GraphQL::Dig

        # The Ruby-style arguments hash, ready for a resolver.
        # This hash is the one used at runtime.
        #
        # @return [Hash<Symbol, Object>]
        attr_reader :keyword_arguments

        def initialize(keyword_arguments:, argument_values:)
          @keyword_arguments = keyword_arguments
          @argument_values = argument_values
        end

        # Yields `ArgumentValue` instances which contain detailed metadata about each argument.
        def each_value
          argument_values.each { |arg_v| yield(arg_v) }
        end

        # @return [Hash{Symbol => ArgumentValue}]
        attr_reader :argument_values

        def_delegators :@keyword_arguments, :key?, :[], :keys, :each, :values

        def inspect
          "#<#{self.class} @keyword_arguments=#{keyword_arguments.inspect}>"
        end
      end
    end
  end
end
