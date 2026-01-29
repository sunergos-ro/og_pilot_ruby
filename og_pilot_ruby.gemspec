# frozen_string_literal: true

require_relative "lib/og_pilot_ruby/version"

Gem::Specification.new do |spec|
  spec.name = "og_pilot_ruby"
  spec.version = OgPilotRuby::VERSION
  spec.authors = ["Sunergos IT LLC", "Raul Popadineti"]
  spec.email = ["office@sunergos.ro", "raul@sunergos.ro"]

  spec.summary = "Ruby client for the OG Pilot Open Graph image generator."
  spec.description = "Generate OG Pilot image URLs or JSON metadata using signed JWTs."
  spec.homepage = "https://ogpilot.com"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/sunergos-ro/og_pilot_ruby"
  spec.metadata["changelog_uri"] = "#{spec.metadata['source_code_uri']}/commits/main"
  spec.metadata['documentation_uri'] = "#{spec.homepage}/docs"
  spec.metadata['bug_tracker_uri'] = "#{spec.metadata['source_code_uri']}/issues"

  # Use Dir.glob to list all files within the lib directory
  spec.files = Dir.glob('lib/**/*') + ['README.md', 'LICENSE']
  spec.require_paths = ['lib']

  spec.add_dependency "jwt", "~> 3.1"
  spec.add_dependency 'zeitwerk', '~> 2'

  spec.add_development_dependency "gem-release", "~> 2.2"
end
