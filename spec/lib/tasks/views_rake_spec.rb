require 'spec_helper'

describe "database view clearing rake task" do
  before(:each) do
    Rake.application = @rake = Rake::Application.new
    load 'active_record/railties/databases.rake'
    load "lib/tasks/views.rake"
    $stdout.stub(:write) # suppress output from rake task
  end

  describe "rake db:clear_views" do
    before(:each) do
      @rake_task_name = "db:clear_views"
      Rake::Task[@rake_task_name].reenable
    end

    it "executes the rake task" do
      schema_migrations = Object.new
      schema_migrations.should_receive(:table_name).and_return("schema_migrations")

      another_table = Object.new
      another_table.should_receive(:table_name).exactly(2).times.and_return("another_table")
      another_table.should_receive(:view_name).and_return("another_table_anonymized")
      another_table.should_receive(:clear_view)

      ActiveRecord::Base.should_receive(:subclasses).and_return([schema_migrations, another_table])
      @rake[@rake_task_name].invoke
    end
  end

  describe "rake db:generate_views" do
    before(:each) do
      @rake_task_name = "db:generate_views"
      Rake::Task[@rake_task_name].reenable
    end

    it "executes the rake task" do
      schema_migrations = Object.new
      schema_migrations.should_receive(:table_name).and_return("schema_migrations")

      nonexistent = Object.new
      nonexistent.should_receive(:table_name).exactly(2).times.and_return("nonexistent")
      nonexistent.should_receive(:skip_anonymization?)

      skip_anonymization = Object.new
      skip_anonymization.should_receive(:table_name).and_return("skip")
      skip_anonymization.should_receive(:skip_anonymization?).and_return(true)

      another_table = Object.new
      another_table.should_receive(:table_name).exactly(3).times.and_return("another_table")
      another_table.should_receive(:view_name).and_return("another_table_anonymized")
      another_table.should_receive(:create_view)
      another_table.should_receive(:skip_anonymization?)

      ActiveRecord::Base.should_receive(:subclasses)
                        .and_return([schema_migrations, another_table,
                                     nonexistent, skip_anonymization])
      connection = Object.new
      ActiveRecord::Base.should_receive(:connection).exactly(2).times
                        .and_return(connection)
      connection.should_receive(:table_exists?).with("nonexistent").and_return(false)
      connection.should_receive(:table_exists?).with("another_table").and_return(true)
      @rake[@rake_task_name].invoke
    end
  end
end
