# frozen_string_literal: true

require "rails/generators"

module OgPilotRuby
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Creates an OG Pilot initializer\n" \
        "Usage: rails g og_pilot_ruby:install"

      def copy_initializer
        template "initializer.rb", "config/initializers/og_pilot_ruby.rb"
      end
    end
  end
end
