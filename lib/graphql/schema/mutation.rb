# frozen_string_literal: true

module GraphQL
  class Schema
    class Mutation < GraphQL::Schema::Member
      extend GraphQL::Schema::Member::HasFields
      # TODO: also allow overrides for object base class
      extend GraphQL::Schema::Member::HasArguments

      # @param object [Object] the initialize object, pass to {Query.initialize} as `root_value`
      # @param context [GraphQL::Query::Context]
      def initialize(object:, context:, arguments:)
        @object = object
        @context = context
      end

      # @return [Object] the root value of the operation
      attr_reader :object

      # @return [GraphQL::Query::Context]
      attr_reader :context

      # Do the work. Everything happens here.
      # @return [Hash] A key for each field in the return type
      # @return [Object] An object corresponding to the return type
      def perform(**args)
        raise NotImplementedError, "#{self.class.name}#perform should execute side effects"
      end

      class << self
        def payload_type(new_payload_type = nil)
          if new_payload_type
            @payload_type = new_payload_type
          end
          @payload_type ||= generate_payload_type
        end

        def graphql_field
          @graphql_field ||= generate_field
        end

        def graphql_name(new_name = nil)
          if new_name
            @graphql_name = new_name
          end
          @graphql_name ||= self.name.split("::").last
        end

        # An object class to use for deriving payload types
        # @param new_class [Class] Defaults to {GraphQL::Schema::Object}
        # @return [Class]
        def object_class(new_class = nil)
          if new_class
            @object_class = new_class
          end
          @object_class || (superclass.respond_to?(:object_class) ? superclass.object_class : GraphQL::Schema::Object)
        end

        private

        def generate_payload_type
          mutation_name = graphql_name
          mutation_fields = fields

          Class.new(object_class) do
            graphql_name("#{mutation_name}Payload")
            description("Autogenerated return type of #{mutation_name}")
            mutation_fields.each do |name, f|
              field(name, field: f)
            end
          end
        end

        def field_name
          graphql_name.sub(/^[A-Z]/, &:downcase)
        end

        def generate_field
          self.field_class.new(
            field_name,
            payload_type,
            description,
            resolve: self.method(:resolve_field),
            arguments: arguments,
            null: false,
          )
        end

        def resolve_field(obj, args, ctx)
          mutation = self.new(object: obj, arguments: args, context: ctx.query.context)
          mutation.perform(**args.to_kwargs)
        end
      end
    end
  end
end
