require "rake"
require "active_record"

require "activerecord_anonymize/version"
require "activerecord_anonymize/anonymization"
require "activerecord_anonymize/strategies/cond_anonymizer.rb"
require "activerecord_anonymize/strategies/email_anonymizer.rb"
require "activerecord_anonymize/strategies/null_anonymizer.rb"
require "activerecord_anonymize/strategies/overlay_anonymizer.rb"
require "activerecord_anonymize/strategies/static_anonymizer.rb"
require "activerecord_anonymize/strategies/text_anonymizer.rb"

load "active_record/railties/databases.rake"
load "tasks/views.rake"