# encoding: utf-8

module Tidus
  module Query
    def create_query
      "CREATE VIEW #{view_name} AS " +
      "SELECT #{view_columns.join(', ')} " +
      "FROM #{table_name}"
    end

    def create_view
      connection.execute(create_query)
    end

    def clear_query
      "DROP VIEW IF EXISTS #{view_name}"
    end

    def clear_view
      connection.execute(clear_query)
    end
  end
end