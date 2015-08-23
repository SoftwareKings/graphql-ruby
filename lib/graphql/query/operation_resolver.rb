class GraphQL::Query::OperationResolver
  attr_reader :query

  def initialize(operation_definition, query)
    @operation_definition = operation_definition
    @query = query
  end

  def result
    @result ||= execute(@operation_definition, query)
  end

  private

  def execute(op_def, query)
    root = if op_def.operation_type == "query"
      query.schema.query
    elsif op_def.operation_type == "mutation"
      query.schema.mutation
    end
    resolver = GraphQL::Query::SelectionResolver.new(nil, root, op_def.selections, query)
    resolver.result
  end
end
