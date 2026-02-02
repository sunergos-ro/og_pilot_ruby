# frozen_string_literal: true

require "test_helper"
require "uri"
require "og_pilot_ruby/request_store_middleware"

class TestRequestStoreMiddleware < Minitest::Test
  def setup
    Thread.current[:og_pilot_request] = nil
  end

  def teardown
    Thread.current[:og_pilot_request] = nil
  end

  def test_stores_request_in_thread_current
    app = ->(env) { [200, {}, ["OK"]] }
    middleware = OgPilotRuby::RequestStoreMiddleware.new(app)

    captured_request = nil
    capturing_app = lambda do |env|
      captured_request = Thread.current[:og_pilot_request]
      [200, {}, ["OK"]]
    end
    middleware = OgPilotRuby::RequestStoreMiddleware.new(capturing_app)

    env = mock_rack_env("/test/path?foo=bar")
    middleware.call(env)

    assert_kind_of ActionDispatch::Request, captured_request
    assert_equal "/test/path", captured_request.path
  end

  def test_clears_request_after_call_completes
    app = ->(env) { [200, {}, ["OK"]] }
    middleware = OgPilotRuby::RequestStoreMiddleware.new(app)

    env = mock_rack_env("/test/path")
    middleware.call(env)

    assert_nil Thread.current[:og_pilot_request]
  end

  def test_clears_request_even_when_app_raises
    error_app = ->(_env) { raise "App error" }
    middleware = OgPilotRuby::RequestStoreMiddleware.new(error_app)

    env = mock_rack_env("/test/path")

    assert_raises(RuntimeError) { middleware.call(env) }
    assert_nil Thread.current[:og_pilot_request]
  end

  def test_returns_app_response
    app = ->(env) { [201, { "X-Custom" => "header" }, ["Created"]] }
    middleware = OgPilotRuby::RequestStoreMiddleware.new(app)

    env = mock_rack_env("/test/path")
    status, headers, body = middleware.call(env)

    assert_equal 201, status
    assert_equal "header", headers["X-Custom"]
    assert_equal ["Created"], body
  end

  private

  def mock_rack_env(path)
    uri = URI.parse("http://example.com#{path}")
    {
      "REQUEST_METHOD" => "GET",
      "SCRIPT_NAME" => "",
      "PATH_INFO" => uri.path,
      "QUERY_STRING" => uri.query || "",
      "SERVER_NAME" => "example.com",
      "SERVER_PORT" => "80",
      "rack.input" => StringIO.new,
      "rack.url_scheme" => "http"
    }
  end
end
