# OG Pilot Ruby

A small Ruby client for generating OG Pilot Open Graph images via signed JWTs.

## Installation

Add to your Gemfile:

```ruby
gem "og_pilot_ruby"
```

Then install:

```bash
bundle install
```

## Configuration

The default initializer reads from `OG_PILOT_API_KEY` and `OG_PILOT_DOMAIN` automatically.
Override as needed:

```ruby
OgPilotRuby.configure do |config|
  config.api_key = ENV.fetch("OG_PILOT_API_KEY")
  config.domain = ENV.fetch("OG_PILOT_DOMAIN")
end
```

For Rails, drop the snippet above into `config/initializers/og_pilot_ruby.rb`.
You can also generate it with:

```bash
bin/rails og_pilot_ruby:install
```

## Usage

Generate an image URL (follows the redirect returned by OG Pilot). In Rails, you can skip the `require`:

```ruby
require "og_pilot_ruby"

image_url = OgPilotRuby.create_image(
  template: "blog_post",
  title: "How to Build Amazing OG Images",
  description: "A complete guide to social media previews",
  bg_color: "#1a1a1a",
  text_color: "#ffffff",
  author_name: "Jane Smith",
  publish_date: "2024-01-15",
  iat: Time.now.to_i
)
```

If you omit `iat`, OG Pilot will cache the image indefinitely. Provide an `iat` to
refresh the cache daily.

Fetch JSON metadata instead:

```ruby
payload = {
  template: "page",
  title: "Hello OG Pilot"
}

data = OgPilotRuby.create_image(**payload, json: true)
```

## Development

Run tests with:

```bash
bundle exec rake test
```

### Releases

This repo uses `gem-release` to bump versions and tag releases:

```bash
bundle exec gem bump --version patch
bundle exec gem bump --version minor
bundle exec gem bump --version major
bundle exec gem bump --version 1.2.3
```

Then publish:

```bash
bundle exec rake release
```
