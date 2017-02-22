# frozen_string_literal: true
require 'graphql/generators/type_generator'

module GraphQL
  module Generators
    # Generate a union type by name
    # with the specified member types.
    #
    # ```
    # rails g graphql:union SearchResultType ImageType AudioType
    # ```
    class UnionGenerator < TypeGenerator
      desc "Create a GraphQL::UnionType with the given name and possible types"
      source_root File.expand_path('../templates', __FILE__)

      argument :possible_types,
        type: :array,
        default: [],
        banner: "type type ...",
        description: "Possible types for this union (expressed as Ruby or GraphQL)"

      def create_type_file
        template "union.erb", "app/graphql/types/#{type_file_name}.rb"
      end

      private

      def normalized_possible_types
        possible_types.map { |t| self.class.normalize_type_expression(t, mode: :ruby) }
      end
    end
  end
end
