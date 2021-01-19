# frozen_string_literal: true

module GraphQL
  class Schema
    class Resolver
      # Adds `field(...)` helper to resolvers so that they can
      # generate payload types.
      #
      # Or, an already-defined one can be attached with `payload_type(...)`.
      module HasPayloadType
        # Call this method to get the derived return type of the mutation,
        # or use it as a configuration method to assign a return type
        # instead of generating one.
        # @param new_payload_type [Class, nil] If a type definition class is provided, it will be used as the return type of the mutation field
        # @return [Class] The object type which this mutation returns.
        def payload_type(new_payload_type = nil)
          if new_payload_type
            @payload_type = new_payload_type
          end
          @payload_type ||= generate_payload_type
        end

        alias :type :payload_type
        alias :type_expr :payload_type

        def field_class(new_class = nil)
          if new_class
            @field_class = new_class
          elsif defined?(@field_class) && @field_class
            @field_class
          else
            find_inherited_value(:field_class, GraphQL::Schema::Field)
          end
        end

        # An object class to use for deriving return types
        # @param new_class [Class, nil] Defaults to {GraphQL::Schema::Object}
        # @return [Class]
        def object_class(new_class = nil)
          if new_class
            @object_class = new_class
          else
            @object_class || find_inherited_value(:object_class, GraphQL::Schema::Object)
          end
        end

        NO_INTERFACES = [].freeze

        def return_interfaces(new_interfaces = nil)
          if new_interfaces
            @return_interfaces = new_interfaces
          else
            @return_interfaces || find_inherited_value(:return_interfaces, NO_INTERFACES)
          end
        end

        private

        # Build a subclass of {.object_class} based on `self`.
        # This value will be cached as `{.payload_type}`.
        # Override this hook to customize return type generation.
        def generate_payload_type
          resolver_name = graphql_name
          resolver_fields = fields
          interfaces = return_interfaces
          Class.new(object_class) do
            graphql_name("#{resolver_name}Payload")
            implements(*interfaces)
            description("Autogenerated return type of #{resolver_name}")
            resolver_fields.each do |name, f|
              # Reattach the already-defined field here
              # (The field's `.owner` will still point to the mutation, not the object type, I think)
              # Don't re-warn about a method conflict. Since this type is generated, it should be fixed in the resolver instead.
              add_field(f, method_conflict_warning: false)
            end
          end
        end
      end
    end
  end
end
