Dir[File.dirname(__FILE__) + '/../lib/*.rb'].each  { |file| require file }
Dir["./spec/support/*.rb"].each { |f| require f }
require 'active_record'

RSpec.configure do |config|
  # Add ':focus' to a test and rspec will only run this test.
  # The following 3 lines make this possible:
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true

  config.mock_with :rspec do |c|
    c.syntax = [:should, :expect]
  end
  config.expect_with :rspec do |c|
    c.syntax = [:should, :expect]
  end

  ActiveRecord::Base.establish_connection(
    adapter: "sqlite3",
    database: ":memory:"
  )
  require 'db/schema'
end