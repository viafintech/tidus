# encoding: utf-8

require "rake"
require "active_record"

require "tidus/version"
require "tidus/anonymization"
require "tidus/strategies/cond_anonymizer.rb"
require "tidus/strategies/email_anonymizer.rb"
require "tidus/strategies/null_anonymizer.rb"
require "tidus/strategies/overlay_anonymizer.rb"
require "tidus/strategies/static_anonymizer.rb"
require "tidus/strategies/text_anonymizer.rb"

load "active_record/railties/databases.rake"
load "tasks/views.rake"