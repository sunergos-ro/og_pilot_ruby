# frozen_string_literal: true

require "test_helper"

class TestClientHttp < Minitest::Test
  def setup
    @original_env = ENV.to_h

    OgPilotRuby.configure do |config|
      config.api_key = "test_api_key_12345678"
      config.domain = "example.com"
      config.base_url = "https://ogpilot.com"
    end

    @client = OgPilotRuby::Client.new(OgPilotRuby.config)
  end

  def teardown
    ENV.clear
    @original_env.each { |k, v| ENV[k] = v }
    OgPilotRuby.reset_config!
  end

  def test_create_image_posts_to_images_endpoint_and_returns_location
    response = build_response(
      Net::HTTPFound,
      code: 302,
      message: "Found",
      headers: { "Location" => "https://cdn.ogpilot.com/hello.png" }
    )
    fake_http = FakeHttp.new(response)
    jwt_call = {}

    with_stubbed_singleton_method(Net::HTTP, :new, ->(_host, _port) { fake_http }) do
      with_stubbed_singleton_method(OgPilotRuby::JwtEncoder, :encode, lambda { |payload, api_key|
        jwt_call[:payload] = payload
        jwt_call[:api_key] = api_key
        "signed-token"
      }) do
        result = @client.create_image(
          {
            template: "page",
            title: "Hello OG Pilot",
            path: "/docs"
          },
          iat: 1_700_000_000,
          headers: { "X-Test" => "1" }
        )

        assert_equal "https://cdn.ogpilot.com/hello.png", result
      end
    end

    request = fake_http.last_request
    assert_instance_of Net::HTTP::Post, request
    assert_equal "/api/v1/images?token=signed-token", request.path
    assert_equal "1", request["X-Test"]
    refute_equal "application/json", request["Accept"]

    assert_equal "test_api_key_12345678", jwt_call[:api_key]
    assert_equal "example.com", jwt_call[:payload][:iss]
    assert_equal "test_api", jwt_call[:payload][:sub]
    assert_equal 1_700_000_000, jwt_call[:payload][:iat]
    assert_equal "Hello OG Pilot", jwt_call[:payload][:title]
    assert_equal "page", jwt_call[:payload][:template]
    assert_equal "/docs", jwt_call[:payload][:path]
  end

  def test_create_image_with_json_posts_and_parses_response
    response = build_response(
      Net::HTTPOK,
      code: 200,
      message: "OK",
      body: '{"image_url":"https://cdn.ogpilot.com/hello.png"}'
    )
    fake_http = FakeHttp.new(response)

    with_stubbed_singleton_method(Net::HTTP, :new, ->(_host, _port) { fake_http }) do
      with_stubbed_singleton_method(OgPilotRuby::JwtEncoder, :encode, ->(_payload, _api_key) { "json-token" }) do
        result = @client.create_image(
          {
            title: "Hello OG Pilot",
            path: "/pricing"
          },
          json: true
        )

        assert_equal({ "image_url" => "https://cdn.ogpilot.com/hello.png" }, result)
      end
    end

    request = fake_http.last_request
    assert_instance_of Net::HTTP::Post, request
    assert_equal "/api/v1/images?token=json-token", request.path
    assert_equal "application/json", request["Accept"]
  end

  def test_create_image_without_location_falls_back_to_signed_uri
    response = build_response(Net::HTTPOK, code: 200, message: "OK", body: "")
    fake_http = FakeHttp.new(response)

    with_stubbed_singleton_method(Net::HTTP, :new, ->(_host, _port) { fake_http }) do
      with_stubbed_singleton_method(OgPilotRuby::JwtEncoder, :encode, ->(_payload, _api_key) { "no-location-token" }) do
        result = @client.create_image(
          {
            title: "Hello OG Pilot",
            path: "/about"
          }
        )

        assert_equal "https://ogpilot.com/api/v1/images?token=no-location-token", result
      end
    end

    request = fake_http.last_request
    assert_instance_of Net::HTTP::Post, request
    assert_equal "/api/v1/images?token=no-location-token", request.path
  end

  private

  def build_response(klass, code:, message:, body: "", headers: {})
    response = klass.new("1.1", code.to_s, message)
    headers.each { |key, value| response[key] = value }
    response.instance_variable_set(:@read, true)
    response.instance_variable_set(:@body, body)
    response
  end

  def with_stubbed_singleton_method(klass, method, replacement)
    singleton = klass.singleton_class
    alias_name = :"__orig_#{method}_#{object_id}"

    singleton.alias_method(alias_name, method)
    singleton.define_method(method, &replacement)
    yield
  ensure
    singleton.remove_method(method) if singleton.method_defined?(method)

    if singleton.method_defined?(alias_name)
      singleton.alias_method(method, alias_name)
      singleton.remove_method(alias_name)
    end
  end

  class FakeHttp
    attr_accessor :use_ssl, :open_timeout, :read_timeout
    attr_reader :last_request

    def initialize(response)
      @response = response
      @last_request = nil
    end

    def request(request)
      @last_request = request
      @response
    end
  end
end
