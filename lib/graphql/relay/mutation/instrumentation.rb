# frozen_string_literal: true
module GraphQL
  module Relay
    class Mutation
      # @api private
      module Instrumentation
        # Modify mutation `return_field` resolves by wrapping the returned object
        # in a {Mutation::Result}.
        #
        # By using an instrumention, we can apply our wrapper _last_,
        # giving users access to the original resolve function in earlier instrumentation.
        def self.instrument(type, field)
          if field.mutation
            new_resolve = Mutation::Resolve.new(field.mutation, field.resolve_proc, eager: true)
            new_lazy_resolve = Mutation::Resolve.new(field.mutation, field.lazy_resolve_proc, eager: false)
            field.redefine(resolve: new_resolve, lazy_resolve: new_lazy_resolve)
          else
            field
          end
        end
      end
    end
  end
end
