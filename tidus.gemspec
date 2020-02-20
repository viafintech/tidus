# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'tidus/version'

Gem::Specification.new do |spec|
  # For explanations see http://docs.rubygems.org/read/chapter/20
  spec.name          = "tidus"
  spec.version       = Tidus::VERSION
  spec.authors       = ["Tobias Schoknecht"]
  spec.email         = ["tobias.schoknecht@gmail.com"]
  spec.description   = %q{Creates views which allow anonymization of database tables.}
  spec.summary       = %q{Gem for creating anonymization views.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = Dir['lib/**/*.rb', 'lib/**/*.rake'] # Important!
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rake",    "~> 13.0"
  spec.add_development_dependency "rspec",   "~> 3.9"
  spec.add_development_dependency "sqlite3", "~> 1.4"

  spec.add_dependency "activerecord", ">= 3.2"
end
