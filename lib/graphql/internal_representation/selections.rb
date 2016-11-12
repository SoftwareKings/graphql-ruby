module GraphQL
  module InternalRepresentation
    module Selections
      def self.build(query, nodes)
        # { type => { name => nodes } }
        selections = Hash.new { |h,k| h[k] = Hash.new { |h2, k2| h2[k2] = [] } }

        object_types = Set.new

        warden = query.warden
        ctx = query.context

        nodes.each do |node|
          node.typed_children.each_key do |type_cond|
            object_types.merge(warden.possible_types(type_cond))
          end
        end

        nodes.each do |node|
          node.typed_children.each do |type_cond, children|
            object_types.each do |obj_type|
              if GraphQL::Execution::Typecast.compatible?(obj_type, type_cond, ctx)
                children.each do |name, irep_node|
                  selections[obj_type][name] << irep_node
                end
              end
            end
          end
        end

        selections
      end
    end
  end
end
