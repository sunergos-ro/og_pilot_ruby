# frozen_string_literal: true

require "zeitwerk"

loader = Zeitwerk::Loader.for_gem
loader.ignore("#{__dir__}/generators")
loader.ignore("#{__dir__}/og_pilot_ruby/railtie.rb")
loader.setup

module OgPilotRuby
  class << self
    def config
      @config ||= Configuration.new
    end

    def configure
      yield config
    end

    def reset_config!
      @config = Configuration.new
    end

    def client
      Client.new(config)
    end

    def create_image(params = {}, json: false, iat: nil, headers: {}, default: false, **keyword_params)
      params ||= {}
      client.create_image(params.merge(keyword_params), json:, iat:, headers:, default:)
    end
  end
end

if defined?(Rails::Railtie)
  require "og_pilot_ruby/railtie"
end
