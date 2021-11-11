# frozen_string_literal: true
module GraphQL
  class Query
    # This object can be `ctx` in places where there is no query
    class NullContext
      class NullWarden < GraphQL::Schema::Warden
        def visible?(t); true; end
        def visible_field?(field); true; end
        def visible_argument?(arg); true; end
        def visible_type?(type); true; end
        def visible_enum_value?(ev); true; end
      end

      class NullQuery
        def with_error_handling
          yield
        end
      end

      class NullSchema < GraphQL::Schema
      end

      attr_reader :schema, :query, :warden, :dataloader

      def initialize
        @query = NullQuery.new
        @dataloader = GraphQL::Dataloader::NullDataloader.new
        @schema = NullSchema
        @warden = NullWarden.new(
          GraphQL::Filter.new,
          context: self,
          schema: @schema,
        )
      end

      def [](key); end

      def interpreter?
        true
      end

      class << self
        extend Forwardable

        def [](key); end

        def instance
          @instance ||= self.new
        end

        def_delegators :instance, :query, :warden, :schema, :interpreter?, :dataloader
      end
    end
  end
end
