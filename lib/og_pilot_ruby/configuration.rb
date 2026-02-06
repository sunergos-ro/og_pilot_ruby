# frozen_string_literal: true

module OgPilotRuby
  class Configuration
    DEFAULT_BASE_URL = "https://ogpilot.com"
    private_constant :DEFAULT_BASE_URL

    attr_accessor :api_key, :domain, :base_url, :open_timeout, :read_timeout, :strip_extensions

    def initialize
      @api_key = ENV.fetch("OG_PILOT_API_KEY", nil)
      @domain = ENV.fetch("OG_PILOT_DOMAIN", nil)
      @base_url = DEFAULT_BASE_URL
      @open_timeout = 5
      @read_timeout = 10
      @strip_extensions = true
    end
  end
end
