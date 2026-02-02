# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "og_pilot_ruby"

# For testing Rails integration (middleware, request handling)
require "action_dispatch"

require "minitest/autorun"
