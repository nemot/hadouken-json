class Hadouken::SqlBuilder
  include Virtus.model

  attribute :main_class
  attribute :scope
  attribute :schema, Hash, default: {}
  attribute :decorator, Hadouken::Decorator
  attribute :where_condition, Hash

  def self.call(*args)
    new(*args).call
  end

  def call
    return json_build_object_sql(schema) if scope.nil?

    @sql = ''
    @relation = build_relation
    apply_decorator if decorator&.valid?
    apply_where_conditions
    @sql << @relation.select(*columns_to_select).to_sql.gsub(sample_id.to_s, primary_key)

    "SELECT COALESCE(json_agg(a), '[]'::JSON ) FROM (#{@sql}) a"
  end

  private

  def columns_to_select
    columns = []
    columns += static_columns.map { |field, value| "'#{value}' AS '#{field}' " }
    columns += association_columns
    columns += regular_columns.map { |field, column_name| "#{sanitize_column_name(column_name)} AS \"#{field}\"" } 
    columns += decorator.columns_sql if decorator&.valid?
    columns += nested_columns.map { |field, column_schema| "(#{sql_for(column_schema)}) AS \"#{field}\"" }
  end


  def json_build_object_sql(schema)
    <<~EOQ
      SELECT json_build_object(#{(
        static_columns.map { |field, value| "'#{field}', '#{value}'"} +
        regular_columns.map { |field, data| "'#{field}', (#{data})"} +
        nested_columns.map {|field, column_schema| "'#{field}', (#{sql_for(column_schema)})" }
      ).join(', ')})
    EOQ
  end

  def apply_where_conditions
    return unless where_condition.is_a?(Hash) && where_condition.any?

    where_condition.deep_transform_keys! { |k| [unwound_jsonb_table_name,k.to_s].join('.') } if scope_is_jsonb_array?
    @relation.where!(where_condition)
  end

  def apply_decorator
    @sql << decorator.data_table_sql
    @relation.joins!(decorator.join_sql)
  end

  def build_relation
    fail 'Scope should be ActiveRecord::Relation or string' if [ActiveRecord::Relation, String].none? { |klass| scope.is_a?( klass ) }
    return main_class.from(unwound_jsonb_table) if scope_is_jsonb_array?

    scope.is_a?(ActiveRecord::Relation) ? scope : main_class.new(id: sample_id).instance_eval(scope)
  end

  def regular_columns
    schema.extract!(*schema.select{ |_,v| v.is_a?(String) }.keys)
          .inject({}) do |h, (field, column)|
            col = (@relation&.klass&.column_names||[]).include?(column) ? [@relation.klass.table_name, column].join('.') : column
            scope_is_jsonb_array? ? h.merge(field => "#{unwound_jsonb_table_name}.#{column}") : h.merge(field => col)
          end
  end

  def nested_columns
    schema.extract!(*schema.select{ |_,v| v.is_a?(Hash) }.keys)
  end

  def association_columns
    belongs_to_associations = @relation.klass.reflections.select {|_, v| v.is_a?(ActiveRecord::Reflection::BelongsToReflection) }.keys
    split_regex = /^[\.](?<association>#{belongs_to_associations.join('|')})[.]?(?<scope>.+?)[.](?<column>[^.]+)$/

    cols = schema.extract!(*schema.select{ |_, v| v.to_s.starts_with?('.') }.keys)

    cols.map do |json_field, relation_field|
      s = relation_field.match(split_regex)
      reflection = @relation.klass.reflections[s[:association]]
      join_table_name = [reflection.table_name, reflection.object_id].join('_')
      @relation.joins!(<<~EOQ
          LEFT OUTER JOIN #{reflection.table_name} #{join_table_name}
          ON "#{join_table_name}"."#{reflection.join_primary_key}" = "#{@relation.table_name}"."#{reflection.join_foreign_key}"
        EOQ
      )
      # Scope can not be merged now because i need to do named joins
      # @relation.merge!(reflection.klass.instance_eval(s[:scope])) if(s[:scope])
      "\"#{join_table_name}\".\"#{s[:column]}\" AS \"#{json_field}\""
    end
    
  end

  def static_columns
    schema.extract!(*schema.select{ |k,_| k.to_s.starts_with?('_') }.keys)
          .inject({}) { |h, (k, v)| h.merge(k.to_s[1..-1] => v) }
  end

  def sql_for(json_schema)
    self.class.call!(main_class: main_class, schema: json_schema, decorator: decorator)
  end

  def sample_id
    @sample_id ||= Faker::Number.number(digits: 5)
  end

  def primary_key
    "\"#{main_class.table_name}\".\"#{main_class.primary_key}\""
  end

  def sanitize_column_name(column_name)
    column_name.scan(/[.]/).length <= 1 ? "\"#{column_name.split('.').join('"."')}\"" : "(#{column_name})"
  end

  def scope_is_jsonb_array?
    db_column = main_class.columns_hash[scope]
    db_column&.type == :jsonb && JSON.parse(db_column.default.to_s).is_a?(Array)
  end

  def unwound_jsonb_table_name
    ['records_from', scope].join('_')
  end

  def jsonb_type
    [main_class.table_name, scope].join('_')
  end

  def unwound_jsonb_table
    "jsonb_populate_recordset(null::#{jsonb_type}, #{main_class.table_name}.#{scope}) AS #{unwound_jsonb_table_name}"
  end

end
