# encoding: utf-8

module Tidus
  module Query
    def adapter
      connection.instance_values["config"][:adapter]
    end

    def create_query
      "CREATE VIEW #{view_name} AS " +
      "SELECT #{view_columns.join(', ')} " +
      "FROM #{table_name}"
    end

    def create_view
      ([create_query] + grant_queries).each do |query|
        connection.execute(query)
      end
    end

    def clear_query
      "DROP VIEW IF EXISTS #{view_name}"
    end

    def clear_view
      connection.execute(clear_query)
    end

    def grant_queries
      grants = []
      if adapter != "sqlite3"
        Tidus::Settings.access_roles.each do |role|
          grants << "GRANT SELECT ON #{view_name} TO #{role}"
        end
      end
      return grants
    end

  end
end