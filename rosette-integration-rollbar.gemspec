$:.unshift File.join(File.dirname(__FILE__), 'lib')
require 'rosette/integrations/rollbar_integration/version'

Gem::Specification.new do |s|
  s.name     = "rosette-integration-rollbar"
  s.version  = ::Rosette::Integrations::ROLLBAR_INTEGRATION_VERSION
  s.authors  = ["Cameron Dutro", "Matt Low"]
  s.email    = ["camertron@gmail.com"]
  s.homepage = "http://github.com/camertron"

  s.description = s.summary = "Rollbar integration for the Rosette internationalization platform."

  s.platform = Gem::Platform::RUBY
  s.has_rdoc = true

  s.require_path = 'lib'
  s.files = Dir["{lib,spec}/**/*", "Gemfile", "History.txt", "README.md", "Rakefile", "rosette-integration-rollbar.gemspec"]
end
