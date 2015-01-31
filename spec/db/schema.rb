ActiveRecord::Schema.verbose = false
ActiveRecord::Schema.define do
  create_table :example_models do |t|
    t.string :name
    t.string :key
  end
end
