# frozen_string_literal: true

module Hadouken
  module Virtus
    # Polymorphic class to use for coercing ActiveRecord models
    class ActiveRecordRelation < ::Virtus::Attribute
      def coerce(value)
        # Raise an error if we got something other than a relation or array
        fail ::Virtus::CoercionError.new(value.class, self) unless value.is_a?(ActiveRecord::Relation) || value.is_a?(Array)

        value
      end
    end
  end
end
