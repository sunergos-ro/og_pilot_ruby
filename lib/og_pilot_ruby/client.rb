# frozen_string_literal: true

require "json"
require "logger"
require "net/http"
require "uri"

require_relative "error"
require_relative "jwt_encoder"

module OgPilotRuby
  class Client
    ENDPOINT_PATH = "/api/v1/images"
    MAX_REDIRECTS = 5

    def initialize(config)
      @config = config
    end

    def create_image(params = {}, json: false, iat: nil, headers: {}, default: false)
      params ||= {}
      params = params.dup
      # Always include a path; manual overrides win, otherwise resolve from the current request.
      manual_path = params.key?(:path) ? params[:path] : params["path"]
      params.delete("path") if params.key?("path")
      params[:path] = manual_path.to_s.strip.empty? ? resolved_path(default:) : normalize_path(manual_path)

      uri = build_uri(params, iat:)
      response, final_uri = request(uri, json:, headers:)

      if json
        JSON.parse(response.body)
      else
        response["Location"] || final_uri.to_s
      end
    rescue StandardError => e
      log_create_image_failure(e, json:)
      json ? { "image_url" => nil } : nil
    end

    private

      attr_reader :config

      def log_create_image_failure(error, json:)
        mode = json ? "json" : "url"
        message = "OgPilotRuby create_image failed (mode=#{mode}): #{error.class}: #{error.message}"
        create_image_logger&.error(message)
      rescue StandardError
        nil
      end

      def create_image_logger
        if defined?(::Rails) && ::Rails.respond_to?(:logger) && ::Rails.logger
          ::Rails.logger
        else
          @create_image_logger ||= Logger.new($stderr)
        end
      end

      def request(uri, json:, headers:, method: :post, redirects_left: MAX_REDIRECTS)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == "https"
        http.open_timeout = config.open_timeout if config.open_timeout
        http.read_timeout = config.read_timeout if config.read_timeout

        request = build_http_request(method, uri)
        request["Accept"] = "application/json" if json
        headers.each { |key, value| request[key] = value }

        response = http.request(request)
        if response.is_a?(Net::HTTPRedirection)
          location = response["Location"]
          if location && !location.empty?
            raise OgPilotRuby::RequestError, "OG Pilot request failed with too many redirects" if redirects_left <= 0

            redirect_uri = URI.join(uri.to_s, location)
            redirect_method = redirect_method_for(response, method)
            return request(
              redirect_uri,
              json:,
              headers:,
              method: redirect_method,
              redirects_left: redirects_left - 1
            )
          end
        end

        return [response, uri] unless response.is_a?(Net::HTTPClientError) || response.is_a?(Net::HTTPServerError)

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

      def build_http_request(method, uri)
        case method
        when :post
          Net::HTTP::Post.new(uri)
        when :get
          Net::HTTP::Get.new(uri)
        else
          raise ArgumentError, "Unsupported HTTP method: #{method.inspect}"
        end
      end

      def redirect_method_for(response, current_method)
        return current_method unless current_method == :post

        status_code = response.code.to_i
        [307, 308].include?(status_code) ? :post : :get
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

      # Rails-first path resolution with Rack/CGI env fallback.
      def resolved_path(default:)
        return "/" if default

        path = rails_fullpath
        path = env_fullpath if path.nil? || path.empty?
        normalize_path(path)
      end

      def rails_fullpath
        return unless defined?(::Rails)

        request = rails_request_from_store || rails_request_from_thread
        fullpath = request.fullpath if request&.respond_to?(:fullpath)
        fullpath unless fullpath.nil? || fullpath.empty?
      end

      def rails_request_from_store
        return unless defined?(::RequestStore) && ::RequestStore.respond_to?(:store)

        store = ::RequestStore.store
        store[:action_dispatch_request] ||
          store[:"action_dispatch.request"] ||
          store[:request]
      end

      def rails_request_from_thread
        Thread.current[:og_pilot_request] ||
          Thread.current[:action_dispatch_request] ||
          Thread.current[:"action_dispatch.request"] ||
          Thread.current[:request]
      end

      def env_fullpath
        request_uri = ENV["REQUEST_URI"]
        return request_uri unless request_uri.nil? || request_uri.empty?

        original_fullpath = ENV["ORIGINAL_FULLPATH"]
        return original_fullpath unless original_fullpath.nil? || original_fullpath.empty?

        path_info = ENV["PATH_INFO"]
        return build_fullpath_from_path_info(path_info) unless path_info.nil? || path_info.empty?

        request_path = ENV["REQUEST_PATH"]
        return request_path unless request_path.nil? || request_path.empty?

        nil
      end

      def build_fullpath_from_path_info(path_info)
        query = ENV["QUERY_STRING"].to_s
        return path_info if query.empty?

        "#{path_info}?#{query}"
      end

      def normalize_path(path)
        cleaned = path.to_s.strip
        return "/" if cleaned.empty?

        cleaned = extract_request_uri(cleaned)
        cleaned = "/#{cleaned}" unless cleaned.start_with?("/")
        cleaned = strip_extension(cleaned) if config.strip_extensions
        cleaned
      end

      def strip_extension(path)
        path_part, query = path.split("?", 2)

        dir = File.dirname(path_part)
        base = File.basename(path_part)

        # Don't strip dotfiles like "/.hidden" or "/.env" — only strip when
        # there's a non-dot character before the first meaningful dot.
        unless base.match?(/\A\./)  # starts with dot = hidden file, skip
          base = base.sub(/\..+\z/, "")
        end

        stripped = if dir == "/" || dir == "."
                     "/#{base}"
                   else
                     "#{dir}/#{base}"
                   end
        stripped = "/" if stripped.empty?

        query ? "#{stripped}?#{query}" : stripped
      end

      def extract_request_uri(value)
        return value unless value.start_with?("http://", "https://")

        uri = URI.parse(value)
        uri.request_uri || "/"
      rescue URI::InvalidURIError
        value
      end
  end
end
