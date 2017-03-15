# frozen_string_literal: true
require "graphql/execution/lazy/lazy_method_map"
require "graphql/execution/lazy/resolve"
module GraphQL
  module Execution
    # This wraps a value which is available, but not yet calculated, like a promise or future.
    #
    # Calling `#value` will trigger calculation & return the "lazy" value.
    #
    # This is an itty-bitty promise-like object, with key differences:
    # - It has only two states, not-resolved and resolved
    # - It has no error-catching functionality
    # @api private
    class Lazy
      # Traverse `val`, lazily resolving any values along the way
      # @param val [Object] A data structure containing mixed plain values and `Lazy` instances
      # @return void
      def self.resolve(val)
        Resolve.resolve(val)
      end

      # Create a {Lazy} which will get its inner value by calling the block
      # @param get_value_func [Proc] a block to get the inner value (later)
      def initialize(&get_value_func)
        @get_value_func = get_value_func
        @resolved = false
      end

      # @return [Object] The wrapped value, calling the lazy block if necessary
      def value
        if !@resolved
          @resolved = true
          @value = begin
            @get_value_func.call
          rescue GraphQL::ExecutionError => err
            err
          end
        end
        @value
      end

      # @return [Lazy] A {Lazy} whose value depends on another {Lazy}, plus any transformations in `block`
      def then(&block)
        self.class.new {
          block.call(value)
        }
      end
    end
  end
end
