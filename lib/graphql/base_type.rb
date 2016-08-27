module GraphQL
  # The parent for all type classes.
  class BaseType
    include GraphQL::Define::NonNullWithBang
    include GraphQL::Define::InstanceDefinable
    accepts_definitions :name, :description, {
        connection: GraphQL::Define::AssignConnection,
        global_id_field: GraphQL::Define::AssignGlobalIdField,
      }

    lazy_defined_attr_accessor :name, :description

    # @param other [GraphQL::BaseType] compare to this object
    # @return [Boolean] are these types equivalent? (incl. non-null, list)
    def ==(other)
      if other.is_a?(GraphQL::BaseType)
        self.to_s == other.to_s
      else
        super
      end
    end

    # If this type is modifying an underlying type,
    # return the underlying type. (Otherwise, return `self`.)
    def unwrap
      self
    end

    # @return [GraphQL::NonNullType] a non-null version of this type
    def to_non_null_type
      GraphQL::NonNullType.new(of_type: self)
    end

    # @return [GraphQL::ListType] a list version of this type
    def to_list_type
      GraphQL::ListType.new(of_type: self)
    end

    module ModifiesAnotherType
      def unwrap
        self.of_type.unwrap
      end
    end

    # Find out which possible type to use for `value`.
    # Returns self if there are no possible types (ie, not Union or Interface)
    def resolve_type(value)
      self
    end

    module HasPossibleTypes

      # If a (deprecated) `resolve_type` function was provided, call that and warn.
      # Otherwise call `schema.resolve_type` (the proper behavior)
      def legacy_resolve_type(object, ctx)
        if @resolve_type_proc
          resolve_type(object, ctx)
        else
          ctx.schema.resolve_type(object)
        end
      end

      # Return the implementing type for `object`.
      # The default implementation assumes that there's a type with the same name as `object.class.name`.
      # Maybe you'll need to override this in your own interfaces!
      #
      # @param object [Object] the object which needs a type to expose it
      # @param ctx [GraphQL::Query::Context]
      # @return [GraphQL::ObjectType] the type which should expose `object`
      def resolve_type(object, ctx)
        ensure_defined
        warn_resolve_type_deprecated
        instance_exec(object, ctx, &(@resolve_type_proc || DEFAULT_RESOLVE_TYPE))
      end

      # The default implementation of {#resolve_type} gets `object.class.name`
      # and finds a type with the same name
      DEFAULT_RESOLVE_TYPE = -> (object, ctx) {
        type_name = object.class.name
        ctx.schema.possible_types(self).find {|t| t.name == type_name}
      }

      def resolve_type=(new_proc)
        warn_resolve_type_deprecated
        @resolve_type_proc = new_proc || DEFAULT_RESOLVE_TYPE
      end

      def warn_resolve_type_deprecated
        warn("#{self.name}.resolve_type is deprecated; define Schema.resolve_type instead")
      end
    end

    # Print the human-readable name of this type using the query-string naming pattern
    def to_s
      name
    end

    alias :inspect :to_s

    def valid_input?(value)
      validate_input(value).valid?
    end

    def validate_input(value)
      return GraphQL::Query::InputValidationResult.new if value.nil?
      validate_non_null_input(value)
    end

    def coerce_input(value)
      return nil if value.nil?
      coerce_non_null_input(value)
    end

    # Types with fields may override this
    # @param name [String] field name to lookup for this type
    # @return [GraphQL::Field, nil]
    def get_field(name)
      nil
    end

    # During schema definition, types can be defined inside procs or as strings.
    # This function converts it to a type instance
    # @return [GraphQL::BaseType]
    def self.resolve_related_type(type_arg)
      case type_arg
      when Proc
        # lazy-eval it
        type_arg.call
      when String
        # Get a constant by this name
        Object.const_get(type_arg)
      else
        type_arg
      end
    end

    # Get the default connection type for this object type
    def connection_type
      @connection_type ||= define_connection
    end

    # Define a custom connection type for this object type
    def define_connection(**kwargs, &block)
      GraphQL::Relay::ConnectionType.create_type(self, **kwargs, &block)
    end

    # Get the default edge type for this object type
    def edge_type
      @edge_type ||= define_edge
    end

    # Define a custom edge type for this object type
    def define_edge(**kwargs, &block)
      GraphQL::Relay::EdgeType.create_type(self, **kwargs, &block)
    end
  end
end
