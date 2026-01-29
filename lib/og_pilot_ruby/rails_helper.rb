# frozen_string_literal: true

module OgPilotRuby
  module RailsHelper
    def create_image(params = {}, json: false, iat: nil, headers: {}, **keyword_params)
      OgPilotRuby.create_image(params, json:, iat:, headers:, **keyword_params)
    end
  end
end
