# encoding: utf-8

require "rake"
require "active_record"

require "tidus/version"
require "tidus/query"
require "tidus/anonymization"
Dir["#{File.dirname(__FILE__)}/tidus/strategies/**/*.rb"].each { |f| require f }

load "active_record/railties/databases.rake"
load "tasks/views.rake"