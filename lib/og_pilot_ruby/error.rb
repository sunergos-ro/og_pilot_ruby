# frozen_string_literal: true

module OgPilotRuby
  class Error < StandardError; end
  class ConfigurationError < Error; end
  class RequestError < Error; end
end
