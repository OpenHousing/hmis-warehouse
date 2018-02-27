module ArelExtensions
  module Attribute
    def to_sql
      table = relation
      connection = table.engine.connection
      table_name = connection.quote_table_name table.table_name
      column_name = connection.quote_column_name name
      "#{table_name}.#{column_name}"
    end
  end
end
Arel::Attributes::Attribute.include ArelExtensions::Attribute