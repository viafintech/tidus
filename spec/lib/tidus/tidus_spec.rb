require 'spec_helper'

describe Tidus::Anonymization do
  subject(:klass) { ExampleModel }

  before(:each) do
    ActiveRecord::Base.stub(:connection_pool)
  end

  after(:each) do
    klass.view_postfix = nil
    klass.view_name = nil
  end

  context "#view_postfix" do
    it "returns the default view_postfix" do
      klass.view_postfix.should == "anonymized"
    end

    it "returns the set view_postfix" do
      klass.view_postfix = "something_else"
      klass.view_postfix.should == "something_else"
    end
  end

  context "#view_name" do
    it "returns the default view_name" do
      klass.view_name.should == "example_models_anonymized"
    end

    it "concatenats the defined postfix to the view_name" do
      klass.view_postfix = "cookie"
      klass.view_name.should == "example_models_cookie"
    end

    it "returns the set view_name" do
      klass.view_name = "something_else"
      klass.view_name.should == "something_else"
    end
  end

  context "#view_columns" do
    it "returns an array of 'column AS column' strings" do
      klass.view_columns.should == [
        "example_models.id AS id",
        "example_models.name AS name",
        "example_models.key AS key"
      ]
    end
  end

  context "#default_view_columns" do
    it "returns the column names of all columns in table_name.column notation" do
      klass.default_view_columns.should == {
        :id   => "example_models.id",
        :name => "example_models.name",
        :key  => "example_models.key",
      }
    end
  end

  context "#anonymizes" do
    it "raises an exception if no attributes where provided" do
      expect { klass.anonymizes }.to raise_error("Must have at least one attribute")
    end

    it "raises an exception if no strategy was provided" do
      expect { klass.anonymizes :name }.to raise_error("Must have a strategy")
    end

    it "raises an exception if the strategy is unknown" do
      expect {
        klass.anonymizes :name, :strategy => :unknown
      }.to raise_error("Unknown anonymizer: 'Unknown'")
    end

    it "allows the use of a class name string as strategy" do
      klass.anonymizes :name, :strategy => 'Tidus::TestAnonymizer'
    end

    it "allows the use of a class as strategy" do
      klass.anonymizes :name, :strategy => Tidus::TestAnonymizer
    end

    it "sets the view columns with their appropriate strategy" do
      klass.anonymizes(:name, :strategy => :test)
      klass.view_columns.should == [
        "example_models.id AS id",
        "'test'::text AS name",
        "example_models.key AS key"
      ]
    end
  end

  context "query" do
    before(:each) do
      @postgres_config = { "config" => { :adapter => "postgresql" } }
      @create_query = "CREATE VIEW example_models_anonymized AS " +
        "SELECT example_models.id AS id, " +
               "'test'::text AS name, " +
               "example_models.key AS key " +
        "FROM example_models"
      @clear_query = "DROP VIEW IF EXISTS example_models_anonymized"
    end

    context "#create_query" do
      it "builds the query to create a view" do
        klass.create_query.should == @create_query
      end
    end

    context "#clear_query" do
      it "builds the query to clear a view" do
        klass.clear_query.should == @clear_query
      end
    end

    context "#create_view" do
      it "executes the query to create a view" do
        klass.connection.should_receive(:execute)
             .with(klass.create_query)
        klass.create_view
      end
    end

    context "#clear_view" do
      it "executes the query to clear a view" do
        klass.connection.should_receive(:execute)
             .with(klass.clear_query)
        klass.clear_view
      end
    end
  end
end