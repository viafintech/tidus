# encoding: utf-8

module Tidus
  module Query
    def create_query
      "CREATE VIEW #{view_name} AS " +
      "SELECT #{view_columns.join(', ')} " +
      "FROM #{table_name}"
    end

    def create_views
      ([create_query] + grant_queries).each do |query|
        connection.execute(query)
      end
    end

    def clear_query
      "DROP VIEW IF EXISTS #{view_name}"
    end

    def clear_views
      connection.execute(clear_query)
    end

    def grant_queries
      []
      #{ }"GRANT SELECT ON #{view_name} TO #{}"
    end

  end
end