# encoding: utf-8

require "rake"
require "active_record"

require "tidus/version"
require "tidus/query"
require "tidus/settings"
require "tidus/anonymization"
require "tidus/strategies/base_selector"
Dir["#{File.dirname(__FILE__)}/tidus/strategies/**/*.rb"].each { |f| require f }

load "active_record/railties/databases.rake"
load "tasks/views.rake"