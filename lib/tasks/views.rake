namespace :db do
  desc "Clears all the views which are currently existing"
  task :clear_views do
    Rails.application.eager_load! if defined?(Rails)
    ActiveRecord::Base.descendants.each do |c|
      next if c.table_name == "schema_migrations"
      puts "Clearing view '#{c.view_name}' for table '#{c.table_name}'"

      c.clear_views
    end
  end

  desc "Generates all the views for the models"
  task :generate_views do
    Rails.application.eager_load! if defined?(Rails)
    ActiveRecord::Base.descendants.each do |c|
      next if c.table_name == "schema_migrations"

      if ActiveRecord::Base.connection.table_exists? c.table_name
        puts "Generating view '#{c.view_name}' for table '#{c.table_name}'"

        c.create_views
      end
    end
  end
end

Rake::Task["db:migrate"].enhance ["db:clear_views"]
Rake::Task["db:rollback"].enhance ["db:clear_views"]

Rake::Task["db:migrate"].enhance do
  Rake::Task["db:generate_views"].invoke
end

Rake::Task["db:rollback"].enhance do
  Rake::Task["db:generate_views"].invoke
end