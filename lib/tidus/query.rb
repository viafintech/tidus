# encoding: utf-8

module Tidus
  module Query
    def create_view_query_part
      case connection.adapter_name.downcase
      when 'postgresql'
        return 'CREATE OR REPLACE VIEW'
      when 'sqlite'
        return 'CREATE VIEW IF NOT EXISTS'
      else
        return 'CREATE VIEW'
      end
    end

    def create_query
      "#{create_view_query_part} #{view_name} AS " +
      "SELECT #{view_columns.join(', ')} " +
      "FROM #{table_name}"
    end

    def create_view
      # Make sure we have up-to-date column information in case a column was changed
      # in a migration directly before.
      reset_column_information

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
