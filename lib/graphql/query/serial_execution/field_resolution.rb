module GraphQL
  class Query
    class SerialExecution
      class FieldResolution
        attr_reader :irep_node, :parent_type, :target, :execution_context, :field, :arguments

        def initialize(irep_node, parent_type, target, execution_context)
          @irep_node = irep_node
          @parent_type = parent_type
          @target = target
          @execution_context = execution_context
          @field = execution_context.get_field(parent_type, irep_node)
          @arguments = execution_context.query.arguments_for(irep_node, @field)
        end

        def result
          result_name = irep_node.name
          raw_value = get_raw_value
          { result_name => get_finished_value(raw_value) }
        end

        private

        # After getting the value from the field's resolve method,
        # continue by "finishing" the value, eg. executing sub-fields or coercing values
        def get_finished_value(raw_value)
          case raw_value
          when GraphQL::ExecutionError
            raw_value.ast_node = irep_node.ast_node
            raw_value.path = irep_node.path
            execution_context.add_error(raw_value)
          when Array
            list_errors = raw_value.each_with_index.select { |value, _| value.is_a?(GraphQL::ExecutionError) }
            if list_errors.any?
              list_errors.each do |error, index|
                error.ast_node = irep_node.ast_node
                error.path = irep_node.path + [index]
                execution_context.add_error(error)
              end
            end
          end

          strategy_class = GraphQL::Query::SerialExecution::ValueResolution.get_strategy_for_kind(field.type.kind)
          result_strategy = strategy_class.new(raw_value, field.type, target, parent_type, irep_node, execution_context)
          begin
            result_strategy.result
          rescue GraphQL::InvalidNullError => err
            if field.type.kind.non_null?
              raise(err)
            else
              err.parent_error? || execution_context.add_error(err)
              nil
            end
          end
        end

        # Get the result of:
        # - Any middleware on this schema
        # - The field's resolve method
        # If the middleware chain returns a GraphQL::ExecutionError, its message
        # is added to the "errors" key.
        def get_raw_value
          middlewares = execution_context.query.schema.middleware
          field_resolve_step = FieldResolveStep.new(irep_node)
          resolve_arguments = [parent_type, target, field, arguments, execution_context.query.context]
          # only run a middleware chain if there are any middleware
          if middlewares.any?
            chain = GraphQL::Schema::MiddlewareChain.new(
              steps: middlewares + [field_resolve_step],
              arguments: resolve_arguments
            )
            chain.call
          else
            field_resolve_step.call(*resolve_arguments)
          end
        rescue GraphQL::ExecutionError => err
          err
        end


        # A `.call`-able suitable to be the last step in a middleware chain
        class FieldResolveStep
          def initialize(irep_node)
            @irep_node = irep_node
          end

          # Execute the field's resolve method
          def call(_parent_type, parent_object, field_definition, field_args, context, _next = nil)
            # setup
            context.ast_node = @irep_node.ast_node
            context.irep_node = @irep_node

            # resolve
            value = field_definition.resolve(parent_object, field_args, context)

            # teardown
            context.ast_node = nil
            context.irep_node = nil

            # return
            value
          end
        end
      end
    end
  end
end
