require 'spec_helper'

describe ActiveRecord::Anonymization do
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
      expect { klass.anonymizes }.to raise_error("You need to supply at least one attribute")
    end

    it "raises an exception if no strategy was provided" do
      expect { klass.anonymizes :name }.to raise_error("You need to supply a strategy")
    end

    it "raises an exception if the strategy is unknown" do
      expect { 
        klass.anonymizes :name, :strategy => :unknown
      }.to raise_error("Unknown anonymizer: 'Unknown'")
    end

    it "allows the use of a class name string as strategy" do
      klass.anonymizes :name, :strategy => 'ActiveRecordAnonymize::TestAnonymizer'
    end

    it "allows the use of a class as strategy" do
      klass.anonymizes :name, :strategy => ActiveRecordAnonymize::TestAnonymizer
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
end