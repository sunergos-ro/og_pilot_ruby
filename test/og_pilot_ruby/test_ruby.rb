# frozen_string_literal: true

require "test_helper"
require "og_pilot_ruby/rails_helper"

class OgPilotRubyTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil OgPilotRuby::VERSION
  end

  def test_configuration_defaults_to_env
    ENV["OG_PILOT_API_KEY"] = "testkey12345678"
    ENV["OG_PILOT_DOMAIN"] = "example.com"

    config = OgPilotRuby::Configuration.new

    assert_equal "testkey12345678", config.api_key
    assert_equal "example.com", config.domain
  ensure
    ENV.delete("OG_PILOT_API_KEY")
    ENV.delete("OG_PILOT_DOMAIN")
  end

  def test_jwt_encoder_returns_token
    token = OgPilotRuby::JwtEncoder.encode({ "sub" => "test" }, "secret")
    assert_kind_of String, token
  end

  def test_module_level_create_image_delegates_to_client
    calls = {}
    client = Class.new do
      define_method(:create_image) do |params = {}, json:, iat:, headers:, default:|
        calls[:params] = params
        calls[:json] = json
        calls[:iat] = iat
        calls[:headers] = headers
        calls[:default] = default
        "ok"
      end
    end.new

    with_stubbed_singleton_method(OgPilotRuby, :client, -> { client }) do
      result = OgPilotRuby.create_image(
        { title: "Hello" },
        json: true,
        iat: 123,
        headers: { "X-Test" => "1" },
        template: "page"
      )

      assert_equal "ok", result
      assert_equal({ title: "Hello", template: "page" }, calls[:params])
      assert_equal true, calls[:json]
      assert_equal 123, calls[:iat]
      assert_equal({ "X-Test" => "1" }, calls[:headers])
      assert_equal false, calls[:default]
    end
  end

  def test_rails_helper_delegates_to_module
    calls = {}

    stub = lambda do |params = {}, json: false, iat: nil, headers: {}, default: false, **keyword_params|
      calls[:params] = params
      calls[:json] = json
      calls[:iat] = iat
      calls[:headers] = headers
      calls[:default] = default
      calls[:keyword_params] = keyword_params
      "ok"
    end

    with_stubbed_singleton_method(OgPilotRuby, :create_image, stub) do
      klass = Class.new do
        include OgPilotRuby::RailsHelper
      end

      result = klass.new.create_image(
        { title: "Hello" },
        json: true,
        iat: 123,
        headers: { "X-Test" => "1" },
        template: "page"
      )

      assert_equal "ok", result
      assert_equal({ title: "Hello" }, calls[:params])
      assert_equal true, calls[:json]
      assert_equal 123, calls[:iat]
      assert_equal({ "X-Test" => "1" }, calls[:headers])
      assert_equal false, calls[:default]
      assert_equal({ template: "page" }, calls[:keyword_params])
    end
  end

  private

  def with_stubbed_singleton_method(klass, method, replacement)
    singleton = klass.singleton_class
    alias_name = :"__orig_#{method}"

    singleton.alias_method(alias_name, method)
    singleton.define_method(method, &replacement)
    yield
  ensure
    if singleton.method_defined?(method)
      singleton.remove_method(method)
    end

    if singleton.method_defined?(alias_name)
      singleton.alias_method(method, alias_name)
      singleton.remove_method(alias_name)
    end
  end
end
