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
      expect(schema_migrations).to receive(:table_name).and_return("schema_migrations")

      ar_internal_metadata = Object.new
      expect(ar_internal_metadata).to receive(:table_name).and_return("ar_internal_metadata")

      another_table = Object.new
      expect(another_table)
        .to receive(:table_name)
        .exactly(2).times
        .and_return("another_table")
      expect(another_table)
        .to receive(:view_name)
        .and_return("another_table_anonymized")
      expect(another_table)
        .to receive(:clear_view)

      expect(ActiveRecord::Base)
        .to receive(:descendants)
        .and_return([schema_migrations, ar_internal_metadata, another_table])
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
      expect(schema_migrations).to receive(:table_name).and_return("schema_migrations")

      ar_internal_metadata = Object.new
      expect(ar_internal_metadata).to receive(:table_name).and_return("ar_internal_metadata")

      nonexistent = Object.new
      expect(nonexistent).to receive(:table_name).exactly(2).times.and_return("nonexistent")
      expect(nonexistent).to receive(:skip_anonymization?)

      skip_anonymization = Object.new
      skip_anonymization.should_receive(:table_name).and_return("skip")
      skip_anonymization.should_receive(:skip_anonymization?).and_return(true)

      another_table = Object.new
      expect(another_table).to receive(:table_name).exactly(3).times.and_return("another_table")
      expect(another_table).to receive(:view_name).and_return("another_table_anonymized")
      expect(another_table).to receive(:create_view)
      expect(another_table).to receive(:skip_anonymization?)

      expect(ActiveRecord::Base)
        .to receive(:descendants)
        .and_return(
          [
            schema_migrations,
            ar_internal_metadata,
            another_table,
            nonexistent,
            skip_anonymization,
          ],
        )
      connection = Object.new
      expect(ActiveRecord::Base)
        .to receive(:connection)
        .exactly(2).times
        .and_return(connection)
      expect(connection)
        .to receive(:table_exists?)
        .with("nonexistent")
        .and_return(false)
      expect(connection)
        .to receive(:table_exists?)
        .with("another_table")
        .and_return(true)
      @rake[@rake_task_name].invoke
    end
  end
end
