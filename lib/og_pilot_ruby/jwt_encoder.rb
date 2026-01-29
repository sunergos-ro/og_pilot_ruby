# frozen_string_literal: true

require "jwt"

module OgPilotRuby
  class JwtEncoder
    ALGORITHM = "HS256"

    def self.encode(payload, api_key)
      JWT.encode(payload, api_key, ALGORITHM)
    end
  end
end
