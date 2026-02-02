# frozen_string_literal: true

module OgPilotRuby
  # Middleware that stores the current request in Thread.current
  # so OgPilotRuby::Client can access it for path resolution.
  class RequestStoreMiddleware
    def initialize(app)
      @app = app
    end

    def call(env)
      request = ActionDispatch::Request.new(env)
      Thread.current[:og_pilot_request] = request
      @app.call(env)
    ensure
      Thread.current[:og_pilot_request] = nil
    end
  end
end
