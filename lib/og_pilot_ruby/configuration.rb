# frozen_string_literal: true

module OgPilotRuby
  class Configuration
    DEFAULT_BASE_URL = "https://ogpilot.com"
    private_constant :DEFAULT_BASE_URL

    attr_accessor :api_key, :domain, :base_url, :open_timeout, :read_timeout,
                  :strip_extensions, :strip_query_parameters, :image_type,
                  :quality, :max_bytes, :cache_store, :cache_ttl

    def initialize
      @api_key = ENV.fetch("OG_PILOT_API_KEY", nil)
      @domain = ENV.fetch("OG_PILOT_DOMAIN", nil)
      @base_url = DEFAULT_BASE_URL
      @open_timeout = 5
      @read_timeout = 10
      @strip_extensions = true
      @strip_query_parameters = false
      @image_type = nil
      @quality = nil
      @max_bytes = nil
      @cache_store = nil
      @cache_ttl = 86400
    end
  end
end
