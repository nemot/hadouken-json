# frozen_string_literal: true

class Hadouken::Decorator
  attr_accessor :relation
  class << self 
    def columns(column_names, *args)
      @@column_names = column_names.is_a?(Array) ? column_names.map(&:to_s) : []
      @@mapping = args[0].is_a?(Hash) ? args[0] : {}
      
      fail "Please specify column names for #{self.class}" if @@column_names.empty?
      fail "Please specify mapping of a columns for #{self.class}" if @@mapping.empty?
    end
  end

  def initialize(relation)
    @relation = relation
  end

  def valid?
    @@column_names.present?
  end

  def join_sql
    "LEFT OUTER JOIN \"#{table_name}\" ON #{join_condition}"
  end

  def columns_sql
    columns_to_exclude = (@@mapping.keys+@@mapping.values).map(&:to_s)
    (@@column_names - columns_to_exclude).map do |column|
      "\"#{table_name}\".\"#{column.downcase}\" AS #{column}"
    end
  end

  def data
    fail "#{self.class} does not implement #data"
  end

  def data_table_sql
    "WITH #{table_name}(#{@@column_names.join(', ')}) AS ( VALUES #{values_sql} ) "
  end


  private

  def join_condition
    @@mapping.map { |decorator_column, relation_column|
      "\"#{@relation.table_name}\".\"#{relation_column}\" = \"#{table_name}\".\"#{decorator_column}\""
    }.join(' AND ')
  end

  def sanitize(value)
    ActiveRecord::Base::sanitize_sql(value)
  end

  def values_sql
    values.map { |vals| "(#{vals.map{|v| "'#{sanitize(v)}'"}.join(', ') })"  }.join(', ')
  end

  def values
    data.present? ? data : [ @@column_names.map{|_| ''} ]
  end

  def table_name
    @table_name ||= self.class.name.underscore.gsub('/','_')
  end
end
