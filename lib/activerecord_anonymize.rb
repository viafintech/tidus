require "rake"
require "active_record"

require "activerecord_anonymize/version"
require "activerecord_anonymize/anonymization"
require "activerecord_anonymize/anonymizers/text_anonymizer.rb"
require "activerecord_anonymize/anonymizers/key_anonymizer.rb"
require "activerecord_anonymize/anonymizers/md5_anonymizer.rb"

load "active_record/railties/databases.rake"
load "tasks/views.rake"