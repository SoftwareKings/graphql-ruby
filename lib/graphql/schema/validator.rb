# frozen_string_literal: true

module GraphQL
  class Schema
    class Validator
      # The thing being validated
      # @return [GraphQL::Schema::Argument, GraphQL::Schema::Field, GraphQL::Schema::Resolver, Class<GraphQL::Schema::InputObject>]
      attr_reader :validated

      # TODO should this implement `if:` and `unless:` ?
      # @param argument [GraphQL::Schema::Argument, GraphQL::Schema::Field, GraphQL::Schema::Resolver, Class<GraphQL::Schema::InputObject>] The argument or argument owner this validator is attached to
      # @param allow_blank [Boolean] if `true`, then objects that respond to `.blank?` and return true for `.blank?` will skip this validation
      # @param allow_null [Boolean] if `true`, then incoming `null`s will skip this validation
      def initialize(validated, allow_blank: false, allow_null: false)
        @validated = validated
        @allow_blank = allow_blank
        @allow_null = allow_null
      end

      # @param object [Object] The application object that this argument's field is being resolved for
      # @param context [GraphQL::Query::Context]
      # @param value [Object] The client-provided value for this argument (after parsing and coercing by the input type)
      # @return [nil, Array<String>, String] Error message or messages to add
      def validate(object, context, value)
        raise GraphQL::RequiredImplementationMissingError, "Validator classes should implement #validate"
      end

      # This is called by the validation system and eventually calls {#validate}.
      # @api private
      def apply(object, context, value, as:)
        if value.nil?
          if @allow_null
            nil # skip this
          else
            "#{as.path} can't be null"
          end
        elsif value.respond_to?(:blank?) && value.blank?
          if @allow_blank
            nil # skip this
          else
            "#{as.path} can't be blank"
          end
        else
          validate(object, context, value)
        end
      end

      # This is like `String#%`, but it supports the case that only some of `string`'s
      # values are present in `substitutions`
      def partial_format(string, substitutions)
        substitutions.each do |key, value|
          sub_v = value.is_a?(String) ? value : value.to_s
          string = string.gsub("%{#{key}}", sub_v)
        end
        string
      end

      # @param validates_hash [Hash, nil] A configuration passed as `validates:`
      # @return [Array<Validator>]
      def self.from_config(schema_member, validates_hash)
        if validates_hash.nil? || validates_hash.empty?
          EMPTY_ARRAY
        else
          validates_hash.map do |validator_name, options|
            validator_class = all_validators[validator_name] || raise(ArgumentError, "unknown validation: #{validator_name.inspect}")
            validator_class.new(schema_member, **options)
          end
        end
      end

      def self.install(name, validator)
        all_validators[name] = validator
      end

      class << self
        attr_accessor :all_validators
      end

      self.all_validators = {}

      include Schema::FindInheritedValue::EmptyObjects

      class ValidationFailedError < GraphQL::ExecutionError
        attr_reader :errors

        def initialize(errors:)
          @errors = errors
          super(errors.join(", "))
        end
      end

      # @param validators [Array<Validator>]
      # @param object [Object]
      # @param context [Query::Context]
      # @param value [Object]
      # @return [void]
      # @raises [ValidationFailedError]
      def self.validate!(validators, object, context, value, as: nil)
        # Assuming the default case is no errors, reduce allocations in that case.
        # This will be replaced with a mutable array if we actually get any errors.
        all_errors = EMPTY_ARRAY

        validators.each do |validator|
          validated = as || validator.validated
          errors = validator.apply(object, context, value, as: validated)
          if errors &&
            (errors.is_a?(Array) && errors != EMPTY_ARRAY) ||
            (errors.is_a?(String))
            if all_errors.frozen? # It's empty
              all_errors = []
            end
            interpolation_vars = { validated: validated.path }
            if errors.is_a?(String)
              all_errors << (errors % interpolation_vars)
            else
              errors = errors.map { |e| e % interpolation_vars }
              all_errors.concat(errors)
            end
          end
        end

        if all_errors.any?
          raise ValidationFailedError.new(errors: all_errors)
        end
        nil
      end
    end
  end
end


require "graphql/schema/validator/length_validator"
GraphQL::Schema::Validator.install(:length, GraphQL::Schema::Validator::LengthValidator)
require "graphql/schema/validator/numericality_validator"
GraphQL::Schema::Validator.install(:numericality, GraphQL::Schema::Validator::NumericalityValidator)
require "graphql/schema/validator/format_validator"
GraphQL::Schema::Validator.install(:format, GraphQL::Schema::Validator::FormatValidator)
require "graphql/schema/validator/inclusion_validator"
GraphQL::Schema::Validator.install(:inclusion, GraphQL::Schema::Validator::InclusionValidator)
require "graphql/schema/validator/exclusion_validator"
GraphQL::Schema::Validator.install(:exclusion, GraphQL::Schema::Validator::ExclusionValidator)
require "graphql/schema/validator/required_validator"
GraphQL::Schema::Validator.install(:required, GraphQL::Schema::Validator::RequiredValidator)
