# frozen_string_literal: true

if defined?(Rails::Railtie)
  require_relative "request_store_middleware"

  module OgPilotRuby
    # Rails integration for OG Pilot Ruby
    class Railtie < Rails::Railtie
      initializer 'og_pilot_ruby.inflections' do
        ActiveSupport::Inflector.inflections(:en) do |inflect|
          inflect.acronym 'OgPilotRuby'
        end
      end

      initializer 'og_pilot_ruby.middleware' do |app|
        app.middleware.use OgPilotRuby::RequestStoreMiddleware
      end
    end
  end
end
