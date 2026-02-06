# frozen_string_literal: true

require "zeitwerk"

loader = Zeitwerk::Loader.for_gem
loader.ignore("#{__dir__}/generators")
loader.ignore("#{__dir__}/og_pilot_ruby/railtie.rb")
loader.setup

module OgPilotRuby
  class << self
    # Returns the current {Configuration} instance, initializing one with
    # defaults when accessed for the first time.
    #
    # @return [OgPilotRuby::Configuration]
    def config
      @config ||= Configuration.new
    end

    # Yields the current {Configuration} for block-style setup.
    #
    # @yieldparam config [OgPilotRuby::Configuration]
    # @return [void]
    #
    # @example
    #   OgPilotRuby.configure do |config|
    #     config.api_key = ENV.fetch("OG_PILOT_API_KEY")
    #     config.domain  = ENV.fetch("OG_PILOT_DOMAIN")
    #   end
    def configure
      yield config
    end

    # Resets the configuration to a fresh {Configuration} instance.
    # Primarily useful in tests.
    #
    # @return [OgPilotRuby::Configuration]
    def reset_config!
      @config = Configuration.new
    end

    # Returns a new {Client} instance wired to the current configuration.
    #
    # @return [OgPilotRuby::Client]
    def client
      Client.new(config)
    end

    # Generates an Open Graph image URL via OG Pilot.
    #
    # All image parameters and request options are passed as keyword arguments.
    # Defaults to the +page+ template when +template+ is omitted.
    #
    # == Core parameters
    #   template    - String template name (default: +"page"+).
    #   title       - String primary title text (*required*).
    #   description - String subtitle or supporting text.
    #   logo_url    - String logo image URL.
    #   image_url   - String hero image URL.
    #   bg_color    - String background color (hex format).
    #   text_color  - String text color (hex format).
    #   path        - String request path for analytics context.
    #
    # == Request options
    #   iat     - Integer issued-at timestamp for daily cache busting.
    #   json    - Boolean when +true+, returns parsed JSON metadata
    #             instead of an image URL (default: +false+).
    #   headers - Hash of additional HTTP headers to include.
    #   default - Boolean forces +path+ to +"/"+ when +true+
    #             (default: +false+).
    #
    # @param options [Hash] keyword arguments containing image parameters
    #   and request options.
    # @return [String] the resolved image URL when +json+ is +false+.
    # @return [Hash]   the parsed JSON response when +json+ is +true+.
    #
    # @example Generate an image URL
    #   OgPilotRuby.create_image(
    #     template: "blog_post",
    #     title:    "How to Build Amazing OG Images",
    #     iat:      Time.now.to_i
    #   )
    #
    # @example Fetch JSON metadata
    #   OgPilotRuby.create_image(title: "Hello OG Pilot", json: true)
    def create_image(**options)
      request_opts = extract_request_options!(options)
      client.create_image(options, **request_opts)
    end

    # Generates an Open Graph image using the +blog_post+ template.
    #
    # == Template parameters
    #   title             - String primary title text (*required*).
    #   author_name       - String author display name.
    #   author_avatar_url - String author avatar image URL.
    #   publish_date      - String publication date (ISO 8601).
    #
    # Accepts all core parameters and request options documented on
    # {.create_image}.
    #
    # @param options [Hash] keyword arguments.
    # @return [String] the resolved image URL when +json+ is +false+.
    # @return [Hash]   the parsed JSON response when +json+ is +true+.
    #
    # @example
    #   OgPilotRuby.create_blog_post_image(
    #     title:        "How to Build Amazing OG Images",
    #     author_name:  "Jane Smith",
    #     publish_date: "2024-01-15"
    #   )
    def create_blog_post_image(**options)
      create_image(**options.merge(template: "blog_post"))
    end

    # Generates an Open Graph image using the +podcast+ template.
    #
    # == Template parameters
    #   title        - String primary title text (*required*).
    #   episode_date - String episode date (ISO 8601).
    #
    # Accepts all core parameters and request options documented on
    # {.create_image}.
    #
    # @param options [Hash] keyword arguments.
    # @return [String] the resolved image URL when +json+ is +false+.
    # @return [Hash]   the parsed JSON response when +json+ is +true+.
    #
    # @example
    #   OgPilotRuby.create_podcast_image(
    #     title:        "The Future of Ruby",
    #     episode_date: "2024-03-01"
    #   )
    def create_podcast_image(**options)
      create_image(**options.merge(template: "podcast"))
    end

    # Generates an Open Graph image using the +product+ template.
    #
    # == Template parameters
    #   title                - String primary title text (*required*).
    #   unique_selling_point - String product USP.
    #
    # Accepts all core parameters and request options documented on
    # {.create_image}.
    #
    # @param options [Hash] keyword arguments.
    # @return [String] the resolved image URL when +json+ is +false+.
    # @return [Hash]   the parsed JSON response when +json+ is +true+.
    #
    # @example
    #   OgPilotRuby.create_product_image(
    #     title:                "Wireless Headphones",
    #     unique_selling_point: "50-hour battery life"
    #   )
    def create_product_image(**options)
      create_image(**options.merge(template: "product"))
    end

    # Generates an Open Graph image using the +event+ template.
    #
    # == Template parameters
    #   title          - String primary title text (*required*).
    #   event_date     - String event date.
    #   event_location - String event location.
    #
    # Accepts all core parameters and request options documented on
    # {.create_image}.
    #
    # @param options [Hash] keyword arguments.
    # @return [String] the resolved image URL when +json+ is +false+.
    # @return [Hash]   the parsed JSON response when +json+ is +true+.
    #
    # @example
    #   OgPilotRuby.create_event_image(
    #     title:          "RubyConf 2024",
    #     event_date:     "2024-11-13",
    #     event_location: "Chicago, IL"
    #   )
    def create_event_image(**options)
      create_image(**options.merge(template: "event"))
    end

    # Generates an Open Graph image using the +book+ template.
    #
    # == Template parameters
    #   title              - String primary title text (*required*).
    #   description        - String subtitle or supporting text.
    #   book_author        - String book author name.
    #   book_series_number - String or Integer series number.
    #   book_description   - String book description.
    #   book_genre         - String book genre.
    #
    # Accepts all core parameters and request options documented on
    # {.create_image}.
    #
    # @param options [Hash] keyword arguments.
    # @return [String] the resolved image URL when +json+ is +false+.
    # @return [Hash]   the parsed JSON response when +json+ is +true+.
    #
    # @example
    #   OgPilotRuby.create_book_image(
    #     title:       "The Ruby Way",
    #     book_author: "Hal Fulton",
    #     book_genre:  "Programming"
    #   )
    def create_book_image(**options)
      create_image(**options.merge(template: "book"))
    end

    # Generates an Open Graph image using the +company+ template.
    #
    # == Template parameters
    #   title            - String primary title text (*required*).
    #   description      - String company description.
    #   company_logo_url - String company logo image URL.
    #
    # Note: +image_url+ is ignored for this template.
    #
    # Accepts all core parameters and request options documented on
    # {.create_image}.
    #
    # @param options [Hash] keyword arguments.
    # @return [String] the resolved image URL when +json+ is +false+.
    # @return [Hash]   the parsed JSON response when +json+ is +true+.
    #
    # @example
    #   OgPilotRuby.create_company_image(
    #     title:            "Acme Corp",
    #     description:      "Building the future",
    #     company_logo_url: "https://example.com/logo.png"
    #   )
    def create_company_image(**options)
      create_image(**options.merge(template: "company"))
    end

    # Generates an Open Graph image using the +portfolio+ template.
    #
    # == Template parameters
    #   title - String primary title text (*required*).
    #
    # Accepts all core parameters and request options documented on
    # {.create_image}.
    #
    # @param options [Hash] keyword arguments.
    # @return [String] the resolved image URL when +json+ is +false+.
    # @return [Hash]   the parsed JSON response when +json+ is +true+.
    #
    # @example
    #   OgPilotRuby.create_portfolio_image(title: "My Portfolio")
    def create_portfolio_image(**options)
      create_image(**options.merge(template: "portfolio"))
    end

    private

      # Extracts Ruby-specific request options from +options+, mutating the
      # hash in place so that only image parameters remain.
      #
      # @param options [Hash] the full keyword arguments hash (modified in place).
      # @return [Hash] a keyword hash (+json+, +iat+, +headers+, +default+)
      #   compatible with {Client#create_image}.
      def extract_request_options!(options)
        {
          json:    options.delete(:json) || false,
          iat:     options.delete(:iat),
          headers: options.delete(:headers) || {},
          default: options.delete(:default) || false
        }
      end
  end
end

if defined?(Rails::Railtie)
  require "og_pilot_ruby/railtie"
end
