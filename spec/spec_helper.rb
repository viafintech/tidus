Dir[File.dirname(__FILE__) + '/../lib/*.rb'].each  { |file| require file }
Dir["./spec/support/*.rb"].each { |f| require f }

RSpec.configure do |config|
  # Add ':focus' to a test and rspec will only run this test.
  # The following 3 lines make this possible:
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true

  ActiveRecord::Base.establish_connection(
    adapter: "sqlite3",
    database: ":memory:"
  )
  require 'db/schema'
end