namespace :db do
  desc "Clears all the views which are currently existing"
  task clear_views: :environment do
    Rails.application.eager_load! if defined?(Rails)
    ActiveRecord::Base.subclasses.each do |c|
      next if c.table_name == "schema_migrations"
      puts "Clearing view '#{c.view_name}' for table '#{c.table_name}'"

      c.clear_view
    end
  end

  desc "Generates all the views for the models"
  task generate_views: :environment do
    Rails.application.eager_load! if defined?(Rails)
    ActiveRecord::Base.subclasses.each do |c|
      next if c.table_name == "schema_migrations" || c.skip_anonymization?

      if ActiveRecord::Base.connection.table_exists? c.table_name
        puts "Generating view '#{c.view_name}' for table '#{c.table_name}'"

        c.create_view
      end
    end
  end
end
