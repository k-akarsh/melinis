$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "melinis/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "melinis"
  s.version     = Melinis::VERSION
  s.authors     = ["Kumar Akarsh"]
  s.email       = ["akarsh1357@gmail.com"]
  s.homepage    = "https://github.com/k-akarsh"
  s.summary     = "Melinis makes it super easy to manage Background tasks/jobs."
  s.description = "Melinis makes it super easy to manage Background tasks/jobs."

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 4.2.0"

end
