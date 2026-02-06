# frozen_string_literal: true

require "test_helper"

class TestClientPathResolution < Minitest::Test
  def setup
    @original_env = ENV.to_h
    clear_thread_storage
    clear_env_vars

    OgPilotRuby.configure do |config|
      config.api_key = "test_api_key_12345678"
      config.domain = "example.com"
    end
  end

  def teardown
    clear_thread_storage
    restore_env(@original_env)
    OgPilotRuby.reset_config!
  end

  # Tests for rails_request_from_thread priority

  def test_og_pilot_request_takes_priority_over_action_dispatch_request
    mock_request = MockRequest.new("/og-pilot-path")
    other_request = MockRequest.new("/other-path")

    Thread.current[:og_pilot_request] = mock_request
    Thread.current[:action_dispatch_request] = other_request

    client = OgPilotRuby::Client.new(OgPilotRuby.config)
    path = client.send(:rails_request_from_thread)

    assert_equal mock_request, path
  end

  def test_falls_back_to_action_dispatch_request_when_og_pilot_request_nil
    mock_request = MockRequest.new("/action-dispatch-path")

    Thread.current[:og_pilot_request] = nil
    Thread.current[:action_dispatch_request] = mock_request

    client = OgPilotRuby::Client.new(OgPilotRuby.config)
    path = client.send(:rails_request_from_thread)

    assert_equal mock_request, path
  end

  def test_falls_back_to_action_dispatch_dot_request
    mock_request = MockRequest.new("/dot-request-path")

    Thread.current[:og_pilot_request] = nil
    Thread.current[:action_dispatch_request] = nil
    Thread.current[:"action_dispatch.request"] = mock_request

    client = OgPilotRuby::Client.new(OgPilotRuby.config)
    path = client.send(:rails_request_from_thread)

    assert_equal mock_request, path
  end

  def test_falls_back_to_generic_request
    mock_request = MockRequest.new("/generic-request-path")

    Thread.current[:og_pilot_request] = nil
    Thread.current[:action_dispatch_request] = nil
    Thread.current[:"action_dispatch.request"] = nil
    Thread.current[:request] = mock_request

    client = OgPilotRuby::Client.new(OgPilotRuby.config)
    path = client.send(:rails_request_from_thread)

    assert_equal mock_request, path
  end

  def test_returns_nil_when_no_request_in_thread
    clear_thread_storage

    client = OgPilotRuby::Client.new(OgPilotRuby.config)
    path = client.send(:rails_request_from_thread)

    assert_nil path
  end

  # Tests for resolved_path

  def test_resolved_path_returns_slash_when_default_is_true
    client = OgPilotRuby::Client.new(OgPilotRuby.config)
    path = client.send(:resolved_path, default: true)

    assert_equal "/", path
  end

  def test_resolved_path_falls_back_to_env_fullpath
    ENV["REQUEST_URI"] = "/from-env?query=value"

    client = OgPilotRuby::Client.new(OgPilotRuby.config)
    path = client.send(:resolved_path, default: false)

    assert_equal "/from-env?query=value", path
  end

  def test_resolved_path_returns_slash_when_no_path_available
    clear_thread_storage
    clear_env_vars

    client = OgPilotRuby::Client.new(OgPilotRuby.config)
    path = client.send(:resolved_path, default: false)

    assert_equal "/", path
  end

  # Tests for env_fullpath

  def test_env_fullpath_uses_request_uri_first
    ENV["REQUEST_URI"] = "/request-uri-path"
    ENV["ORIGINAL_FULLPATH"] = "/original-fullpath"

    client = OgPilotRuby::Client.new(OgPilotRuby.config)
    path = client.send(:env_fullpath)

    assert_equal "/request-uri-path", path
  end

  def test_env_fullpath_falls_back_to_original_fullpath
    ENV["REQUEST_URI"] = nil
    ENV["ORIGINAL_FULLPATH"] = "/original-fullpath"

    client = OgPilotRuby::Client.new(OgPilotRuby.config)
    path = client.send(:env_fullpath)

    assert_equal "/original-fullpath", path
  end

  def test_env_fullpath_falls_back_to_path_info_with_query_string
    ENV["REQUEST_URI"] = nil
    ENV["ORIGINAL_FULLPATH"] = nil
    ENV["PATH_INFO"] = "/path-info"
    ENV["QUERY_STRING"] = "foo=bar"

    client = OgPilotRuby::Client.new(OgPilotRuby.config)
    path = client.send(:env_fullpath)

    assert_equal "/path-info?foo=bar", path
  end

  def test_env_fullpath_falls_back_to_request_path
    ENV["REQUEST_URI"] = nil
    ENV["ORIGINAL_FULLPATH"] = nil
    ENV["PATH_INFO"] = nil
    ENV["REQUEST_PATH"] = "/request-path"

    client = OgPilotRuby::Client.new(OgPilotRuby.config)
    path = client.send(:env_fullpath)

    assert_equal "/request-path", path
  end

  def test_env_fullpath_returns_nil_when_all_vars_empty
    clear_env_vars

    client = OgPilotRuby::Client.new(OgPilotRuby.config)
    path = client.send(:env_fullpath)

    assert_nil path
  end

  # Tests for normalize_path

  def test_normalize_path_returns_slash_for_nil
    client = OgPilotRuby::Client.new(OgPilotRuby.config)
    path = client.send(:normalize_path, nil)

    assert_equal "/", path
  end

  def test_normalize_path_returns_slash_for_empty_string
    client = OgPilotRuby::Client.new(OgPilotRuby.config)
    path = client.send(:normalize_path, "")

    assert_equal "/", path
  end

  def test_normalize_path_adds_leading_slash
    client = OgPilotRuby::Client.new(OgPilotRuby.config)
    path = client.send(:normalize_path, "foo/bar")

    assert_equal "/foo/bar", path
  end

  def test_normalize_path_keeps_existing_leading_slash
    client = OgPilotRuby::Client.new(OgPilotRuby.config)
    path = client.send(:normalize_path, "/foo/bar")

    assert_equal "/foo/bar", path
  end

  def test_normalize_path_extracts_path_from_full_url
    client = OgPilotRuby::Client.new(OgPilotRuby.config)
    path = client.send(:normalize_path, "https://example.com/foo/bar?query=1")

    assert_equal "/foo/bar?query=1", path
  end

  # Tests for strip_extensions

  def test_normalize_path_strips_single_extension_when_enabled
    OgPilotRuby.config.strip_extensions = true
    client = OgPilotRuby::Client.new(OgPilotRuby.config)
    path = client.send(:normalize_path, "/docs.md")
    assert_equal "/docs", path
  end

  def test_normalize_path_strips_multiple_extensions_when_enabled
    OgPilotRuby.config.strip_extensions = true
    client = OgPilotRuby::Client.new(OgPilotRuby.config)
    path = client.send(:normalize_path, "/archive.tar.gz")
    assert_equal "/archive", path
  end

  def test_normalize_path_preserves_query_string_when_stripping
    OgPilotRuby.config.strip_extensions = true
    client = OgPilotRuby::Client.new(OgPilotRuby.config)
    path = client.send(:normalize_path, "/docs.md?ref=main")
    assert_equal "/docs?ref=main", path
  end

  def test_normalize_path_does_not_strip_dotfiles
    OgPilotRuby.config.strip_extensions = true
    client = OgPilotRuby::Client.new(OgPilotRuby.config)
    path = client.send(:normalize_path, "/.hidden")
    assert_equal "/.hidden", path
  end

  def test_normalize_path_does_not_strip_when_disabled
    OgPilotRuby.config.strip_extensions = false
    client = OgPilotRuby::Client.new(OgPilotRuby.config)
    path = client.send(:normalize_path, "/docs.md")
    assert_equal "/docs.md", path
  end

  def test_normalize_path_strips_extension_in_nested_path
    OgPilotRuby.config.strip_extensions = true
    client = OgPilotRuby::Client.new(OgPilotRuby.config)
    path = client.send(:normalize_path, "/blog/my-post.html")
    assert_equal "/blog/my-post", path
  end

  def test_normalize_path_does_not_strip_dots_in_middle_segments
    OgPilotRuby.config.strip_extensions = true
    client = OgPilotRuby::Client.new(OgPilotRuby.config)
    path = client.send(:normalize_path, "/my.app/dashboard")
    assert_equal "/my.app/dashboard", path
  end

  def test_normalize_path_handles_path_without_extension
    OgPilotRuby.config.strip_extensions = true
    client = OgPilotRuby::Client.new(OgPilotRuby.config)
    path = client.send(:normalize_path, "/about")
    assert_equal "/about", path
  end

  private

  def clear_thread_storage
    Thread.current[:og_pilot_request] = nil
    Thread.current[:action_dispatch_request] = nil
    Thread.current[:"action_dispatch.request"] = nil
    Thread.current[:request] = nil
  end

  def clear_env_vars
    ENV.delete("REQUEST_URI")
    ENV.delete("ORIGINAL_FULLPATH")
    ENV.delete("PATH_INFO")
    ENV.delete("REQUEST_PATH")
    ENV.delete("QUERY_STRING")
  end

  def restore_env(original)
    ENV.clear
    original.each { |k, v| ENV[k] = v }
  end

  class MockRequest
    attr_reader :fullpath

    def initialize(fullpath)
      @fullpath = fullpath
    end
  end
end
