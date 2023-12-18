# encoding: utf-8

require 'rake'
require 'active_record'

require 'tidus/version'
require 'tidus/query'
require 'tidus/anonymization'
require 'tidus/strategies/base_selector'
Dir["#{File.dirname(__FILE__)}/tidus/strategies/**/*.rb"].each { |f| require f }

if !defined?(Rails)
  load 'tasks/tidus_views.rake'
end
