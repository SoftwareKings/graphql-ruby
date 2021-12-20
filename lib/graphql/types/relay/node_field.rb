# frozen_string_literal: true
module GraphQL
  module Types
    module Relay
      # Don't use this field directly, instead, use one of these approaches:
      #
      # @example Adding this field directly
      #   include GraphQL::Types::Relay::HasNodeField
      #
      # @example Implementing a similar field in your own Query root
      #
      #   field :node, GraphQL::Types::Relay::Node, null: true,
      #     description: "Fetches an object given its ID" do
      #       argument :id, ID, required: true
      #     end
      #
      #   def node(id:)
      #     context.schema.object_from_id(id, context)
      #   end
      #
      def self.const_missing(const_name)
        if const_name == :NodeField
          message = "NodeField is deprecated, use `include GraphQL::Types::Relay::HasNodeField` instead."
          message += "\n(referenced from #{caller(1, 1).first})"
          GraphQL::Deprecation.warn(message)

          DeprecatedNodeField
        else
          super
        end
      end

      DeprecatedNodeField = GraphQL::Schema::Field.new(owner: nil, **HasNodeField.field_options, &HasNodeField.field_block)
    end
  end
end
