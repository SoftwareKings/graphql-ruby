# Starting from a given type, discover other types in the system by
# traversing that type's fields, possible_types, etc
class GraphQL::Schema::TypeReducer
  attr_reader :type, :existing_type_hash

  def initialize(type, existing_type_hash)
    validate_type(type)
    if type.respond_to?(:name) && existing_type_hash.fetch(type.name, nil).equal?(type)
      @result = existing_type_hash
    else
      @type = type
    end
    @existing_type_hash = existing_type_hash
  end

  def result
    @result ||= find_types(type, existing_type_hash)
  end

  # Reduce all of `types` and return the combined result
  def self.find_all(types)
    type_map = GraphQL::Schema::TypeMap.new
    types.reduce(type_map) do |memo, type|
      self.new(type, memo).result
    end
  end

  private

  def find_types(type, type_hash)
    type_hash[type.name] = type
    if type.kind.fields?
      type.fields.each do |name, field|
        reduce_type(field.type, type_hash)
        field.arguments.each do |name, argument|
          reduce_type(argument.type, type_hash)
        end
      end
    end
    if type.kind.object?
      type.interfaces.each do |interface|
        reduce_type(interface, type_hash)
      end
    end
    if type.kind.resolves?
      type.possible_types.each do |possible_type|
        reduce_type(possible_type, type_hash)
      end
    end
    if type.kind.input_object?
      type.input_fields.each do |name, input_field|
        reduce_type(input_field.type, type_hash)
      end
    end

    type_hash
  end

  def reduce_type(type, type_hash)
    unless type.is_a?(GraphQL::BaseType)
      raise GraphQL::Schema::InvalidTypeError.new(type, ["Must be a GraphQL::BaseType"])
    end
    self.class.new(type.unwrap, type_hash).result
  end

  def validate_type(type)
    errors = []
    type_validator = GraphQL::Schema::TypeValidator.new
    type_validator.validate(type, errors)
    if errors.any?
      raise GraphQL::Schema::InvalidTypeError.new(type, errors)
    end
  end
end
