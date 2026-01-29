# frozen_string_literal: true

if defined?(Rails::Railtie)
  module OgPilotRuby
    # Rails integration for OG Pilot Ruby
    class Railtie < Rails::Railtie
      initializer 'og_pilot_ruby.inflections' do
        ActiveSupport::Inflector.inflections(:en) do |inflect|
          inflect.acronym 'OgPilotRuby'
        end
      end
    end
  end
end
