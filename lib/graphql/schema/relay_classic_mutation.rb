# frozen_string_literal: true
require "graphql/types/string"

module GraphQL
  class Schema
    # Mutations that extend this base class get some conventions added for free:
    #
    # - An argument called `clientMutationId` is _always_ added, but it's not passed
    #   to the resolve method. The value is re-inserted to the response. (It's for
    #   client libraries to manage optimistic updates.)
    # - The returned object type always has a field called `clientMutationId` to support that.
    # - The mutation accepts one argument called `input`, `argument`s defined in the mutation
    #   class are added to that input object, which is generated by the mutation.
    #
    # These conventions were first specified by Relay Classic, but they come in handy:
    #
    # - `clientMutationId` supports optimistic updates and cache rollbacks on the client
    # - using a single `input:` argument makes it easy to post whole JSON objects to the mutation
    #   using one GraphQL variable (`$input`) instead of making a separate variable for each argument.
    #
    # @see {GraphQL::Schema::Mutation} for an example, it's basically the same.
    #
    class RelayClassicMutation < GraphQL::Schema::Mutation
      # The payload should always include this field
      field(:client_mutation_id, String, "A unique identifier for the client performing the mutation.", null: true)
      # Relay classic default:
      null(true)

      # Override {GraphQL::Schema::Resolver#resolve_with_support} to
      # delete `client_mutation_id` from the kwargs.
      def resolve_with_support(**inputs)
        # TODO why is this needed?
        if context.interpreter?
          input = inputs[:input]
        else
          input = inputs
        end

        if input
          # This is handled by Relay::Mutation::Resolve, a bit hacky, but here we are.
          input_kwargs = input.to_h
          input_kwargs.delete(:client_mutation_id)
        else
          # Relay Classic Mutations with no `argument`s
          # don't require `input:`
          input_kwargs = {}
        end

        if input_kwargs.any?
          super(input_kwargs)
        else
          super()
        end
      end

      class << self
        # The base class for generated input object types
        # @param new_class [Class] The base class to use for generating input object definitions
        # @return [Class] The base class for this mutation's generated input object (default is {GraphQL::Schema::InputObject})
        def input_object_class(new_class = nil)
          if new_class
            @input_object_class = new_class
          end
          @input_object_class || (superclass.respond_to?(:input_object_class) ? superclass.input_object_class : GraphQL::Schema::InputObject)
        end

        # @param new_input_type [Class, nil] If provided, it configures this mutation to accept `new_input_type` instead of generating an input type
        # @return [Class] The generated {Schema::InputObject} class for this mutation's `input`
        def input_type(new_input_type = nil)
          if new_input_type
            @input_type = new_input_type
          end
          @input_type ||= generate_input_type
        end

        # Extend {Schema::Mutation.field_options} to add the `input` argument
        def field_options
          sig = super
          # Arguments were added at the root, but they should be nested
          sig[:arguments].clear
          sig[:arguments][:input] = { type: input_type, required: true }
          sig
        end

        private

        # Generate the input type for the `input:` argument
        # To customize how input objects are generated, override this method
        # @return [Class] a subclass of {.input_object_class}
        def generate_input_type
          mutation_args = arguments
          mutation_name = graphql_name
          mutation_class = self
          Class.new(input_object_class) do
            graphql_name("#{mutation_name}Input")
            description("Autogenerated input type of #{mutation_name}")
            mutation(mutation_class)
            own_arguments.merge!(mutation_args)
            argument :client_mutation_id, String, "A unique identifier for the client performing the mutation.", required: false
          end
        end
      end
    end
  end
end
