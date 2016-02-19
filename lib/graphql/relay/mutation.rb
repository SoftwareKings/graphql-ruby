module GraphQL
  module Relay
    # Define a Relay mutation:
    #   - give it a name (used for derived inputs & outputs)
    #   - declare its inputs
    #   - declare its outputs
    #   - declare the mutation procedure
    #
    # `resolve` should return a hash with a key for each of the `return_field`s
    #
    # Inputs will also contain a `clientMutationId`
    #
    # @example Updating the name of an item
    #   UpdateNameMutation = GraphQL::Relay::Mutation.define do
    #     name "UpdateName"
    #
    #     input_field :name, !types.String
    #     input_field :itemId, !types.ID
    #
    #     return_field :item, ItemType
    #
    #     resolve -> (inputs, ctx) {
    #       item = Item.find_by_id(inputs[:id])
    #       item.update(name: inputs[:name])
    #       {item: item}
    #     }
    #   end
    #
    #   MutationType = GraphQL::ObjectType.define do
    #     # The mutation object exposes a field:
    #     field :updateName, field: UpdateNameMutation.field
    #   end
    #
    #   # Then query it:
    #   query_string = %|
    #     mutation updateName {
    #       updateName(input: {itemId: 1, name: "new name", clientMutationId: "1234"}) {
    #         item { name }
    #         clientMutationId
    #     }|
    #
    #    GraphQL::Query.new(MySchema, query_string).result
    #    # {"data" => {
    #    #   "updateName" => {
    #    #     "item" => { "name" => "new name"},
    #    #     "clientMutationId" => "1234"
    #    #   }
    #    # }}
    #
    class Mutation
      include GraphQL::DefinitionHelpers::DefinedByConfig
      defined_by_config :name, :description, :return_fields, :input_fields, :resolve
      attr_accessor :name, :description, :return_fields, :input_fields

      def resolve=(proc)
        @resolve_proc = proc
      end

      def field
        @field ||= begin
          field_return_type = self.return_type
          field_input_type = self.input_type
          field_resolve_proc = -> (obj, args, ctx){
            results_hash = @resolve_proc.call(args[:input], ctx)
            Result.new(arguments: args, result: results_hash)
          }
          GraphQL::Field.define do
            type(field_return_type)
            argument :input, !field_input_type
            resolve(field_resolve_proc)
          end
        end
      end

      def return_type
        @return_type ||= begin
          mutation_name = name
          type_name = "#{mutation_name}Payload"
          type_fields = return_fields
          GraphQL::ObjectType.define do
            name(type_name)
            description("Autogenerated return type of #{mutation_name}")
            field :clientMutationId, !types.String
            type_fields.each do |name, field_obj|
              field name, field: field_obj
            end
          end
        end
      end

      def input_type
        @input_type ||= begin
          mutation_name = name
          type_name = "#{mutation_name}Input"
          type_fields = input_fields
          GraphQL::InputObjectType.define do
            name(type_name)
            description("Autogenerated input type of #{mutation_name}")
            input_field :clientMutationId, !types.String
            type_fields.each do |name, field_obj|
              input_field name, field_obj.type, field_obj.description, default_value: field_obj.default_value
            end
          end
        end
      end

      class Result
        attr_reader :arguments, :result
        def initialize(arguments:, result:)
          @arguments = arguments
          @result = result
        end

        def clientMutationId
          arguments[:input][:clientMutationId]
        end

        def method_missing(name, *args, &block)
          if result.key?(name)
            result[name]
          else
            super
          end
        end
      end
    end
  end
end
