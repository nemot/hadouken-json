# frozen_string_literal: true

class Hadouken::Json
  include ::Virtus.model
  attribute :relation, Hadouken::Virtus::ActiveRecordRelation

  def self.call(*args)
    new(*args).call
  end

  def call
    execute_query array_of(structure)
  end

  protected
  
  def array_of(json_schema, *args)
    options = args[0] || {}

    Hadouken::SqlBuilder.call(
      main_class: relation.klass,
      scope: options[:for],
      schema: json_schema,
      decorator: (options[:decorate_with].is_a?(Hadouken::Decorator) ? options[:decorate_with] : nil)
    )
  end

  private

  def execute_query(sql_query)
    ActiveRecord::Base.connection.execute(sql_query).values.first.first
  end
  
end
