class GraphQL::Transform < Parslet::Transform
  # node
  rule(identifier: simple(:i), argument: simple(:a), fields: sequence(:f)) {GraphQL::Syntax::Node.new(identifier: i.to_s, argument: a.to_s, fields: f)}
  # edge
  rule(identifier: simple(:i), calls: sequence(:c), fields: sequence(:f)) { GraphQL::Syntax::Edge.new(identifier: i.to_s, fields: f, calls: c)}
  # field
  rule(identifier: simple(:i)) { GraphQL::Syntax::Field.new(identifier: i.to_s)}
  # call
  rule(identifier: simple(:i), argument: simple(:a)) { GraphQL::Syntax::Call.new(identifier: i.to_s, argument: a.to_s) }
end