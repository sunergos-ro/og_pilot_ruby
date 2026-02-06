# frozen_string_literal: true

module OgPilotRuby
  # View-helper mix-in for Rails controllers and views.
  #
  # Include this module to access all +OgPilotRuby+ image-generation methods
  # as instance methods. Every call is forwarded to the corresponding
  # module-level method, so configuration and client behaviour remain
  # identical.
  #
  # @example In a Rails controller or view
  #   class PagesController < ApplicationController
  #     helper OgPilotRuby::RailsHelper
  #   end
  #
  #   # In a view:
  #   <%= tag.meta property: "og:image", content: create_image(title: "Hello") %>
  module RailsHelper
    # @see OgPilotRuby.create_image
    def create_image(**options)
      OgPilotRuby.create_image(**options)
    end

    # @see OgPilotRuby.create_blog_post_image
    def create_blog_post_image(**options)
      OgPilotRuby.create_blog_post_image(**options)
    end

    # @see OgPilotRuby.create_podcast_image
    def create_podcast_image(**options)
      OgPilotRuby.create_podcast_image(**options)
    end

    # @see OgPilotRuby.create_product_image
    def create_product_image(**options)
      OgPilotRuby.create_product_image(**options)
    end

    # @see OgPilotRuby.create_event_image
    def create_event_image(**options)
      OgPilotRuby.create_event_image(**options)
    end

    # @see OgPilotRuby.create_book_image
    def create_book_image(**options)
      OgPilotRuby.create_book_image(**options)
    end

    # @see OgPilotRuby.create_company_image
    def create_company_image(**options)
      OgPilotRuby.create_company_image(**options)
    end

    # @see OgPilotRuby.create_portfolio_image
    def create_portfolio_image(**options)
      OgPilotRuby.create_portfolio_image(**options)
    end
  end
end
