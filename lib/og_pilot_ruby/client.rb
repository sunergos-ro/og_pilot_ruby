# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

require_relative "error"
require_relative "jwt_encoder"

module OgPilotRuby
  class Client
    ENDPOINT_PATH = "/api/v1/images"

    def initialize(config)
      @config = config
    end

    def create_image(params = {}, json: false, iat: nil, headers: {})
      uri = build_uri(params, iat:)
      response = request(uri, json:, headers:)

      if json
        JSON.parse(response.body)
      else
        response["Location"] || uri.to_s
      end
    end

    private

      attr_reader :config

      def request(uri, json:, headers:)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == "https"
        http.open_timeout = config.open_timeout if config.open_timeout
        http.read_timeout = config.read_timeout if config.read_timeout

        request = Net::HTTP::Get.new(uri)
        request["Accept"] = "application/json" if json
        headers.each { |key, value| request[key] = value }

        response = http.request(request)
        return response unless response.is_a?(Net::HTTPClientError) || response.is_a?(Net::HTTPServerError)

        raise OgPilotRuby::RequestError, "OG Pilot request failed with status #{response.code}: #{response.body}"
      rescue OpenSSL::SSL::SSLError => e
        raise OgPilotRuby::RequestError, "OG Pilot request failed with SSL error: #{e.message}"
      rescue Net::OpenTimeout => e
        raise OgPilotRuby::RequestError, "OG Pilot request timed out: #{e.message}"
      rescue Net::ReadTimeout => e
        raise OgPilotRuby::RequestError, "OG Pilot request timed out: #{e.message}"
      rescue Net::HTTPBadRequest => e
        raise OgPilotRuby::RequestError, "OG Pilot request failed with bad request: #{e.message}"
      rescue Net::HTTPUnauthorized => e
        raise OgPilotRuby::RequestError, "OG Pilot request failed with unauthorized: #{e.message}"
      end

      def build_uri(params, iat:)
        payload = build_payload(params, iat:)
        token = OgPilotRuby::JwtEncoder.encode(payload, api_key!)
        uri = URI.join(config.base_url, ENDPOINT_PATH)
        uri.query = URI.encode_www_form(token: token)
        uri
      end

      def build_payload(params, iat:)
        symbolized = params.transform_keys(&:to_sym)

        symbolized[:iat] = iat.to_i if iat
        symbolized[:iss] ||= domain!
        symbolized[:sub] ||= api_key_prefix

        validate_payload!(symbolized)
        symbolized
      end

      def validate_payload!(payload)
        raise OgPilotRuby::ConfigurationError, "OG Pilot domain is missing" if payload[:iss].nil? || payload[:iss].empty?
        raise OgPilotRuby::ConfigurationError, "OG Pilot API key prefix is missing" if payload[:sub].nil? || payload[:sub].empty?
        raise ArgumentError, "OG Pilot title is required" if payload[:title].nil? || payload[:title].empty?
      end

      def api_key!
        return config.api_key if config.api_key

        raise OgPilotRuby::ConfigurationError, "OG Pilot API key is missing"
      end

      def domain!
        return config.domain if config.domain

        raise OgPilotRuby::ConfigurationError, "OG Pilot domain is missing"
      end

      def api_key_prefix
        api_key!.slice(0, 8)
      end
  end
end
