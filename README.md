# OG Pilot Ruby

> [!IMPORTANT]  
> An active [OG Pilot](https://ogpilot.com?ref=og_pilot_ruby) subscription is required to use this gem.

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
  # config.strip_extensions = true
end
```

For Rails, drop the snippet above into `config/initializers/og_pilot_ruby.rb`.
You can also generate it with:

```bash
bin/rails og_pilot_ruby:install
```

## Usage

Generate an image URL (the client sends a signed `POST` request, then follows the redirect returned by OG Pilot). In Rails, you can skip the `require`:

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

### Fail-safe behavior

`create_image` is non-blocking. If any error occurs (request, configuration,
validation, parsing, etc.), the gem does not raise to your app and logs an
error-level message instead.

- URL mode (`json: false`, default): returns `nil`
- JSON mode (`json: true`): returns `{ "image_url" => nil }`

### Template helpers

`create_image` defaults to the `page` template when `template` is omitted.

Use these helpers to force a specific template:

- `OgPilotRuby.create_blog_post_image(...)`
- `OgPilotRuby.create_podcast_image(...)`
- `OgPilotRuby.create_product_image(...)`
- `OgPilotRuby.create_event_image(...)`
- `OgPilotRuby.create_book_image(...)`
- `OgPilotRuby.create_company_image(...)`
- `OgPilotRuby.create_portfolio_image(...)`

Example:

```ruby
image_url = OgPilotRuby.create_blog_post_image(
  title: "How to Build Amazing OG Images",
  author_name: "Jane Smith",
  publish_date: "2024-01-15"
)
```

## Parameters

The client sends `POST /api/v1/images` requests. All parameters are embedded in the signed JWT payload; the only query param is `token`.
The gem handles `iss` (domain) and `sub` (API key prefix) automatically.

### Core parameters

| Parameter     | Required | Default  | Description                                                   |
|---------------|----------|----------|---------------------------------------------------------------|
| `template`    | No       | `"page"` | Template name                                                 |
| `title`       | Yes      | —        | Primary title text                                            |
| `description` | No       | —        | Subtitle or supporting text                                   |
| `logo_url`    | No       | —        | Logo image URL                                                |
| `image_url`   | No       | —        | Hero image URL                                                |
| `bg_color`    | No       | —        | Background color (hex format)                                 |
| `text_color`  | No       | —        | Text color (hex format)                                       |
| `iat`         | No       | —        | Issued-at timestamp for daily cache busting                   |
| `path`        | No       | auto-set | Request path for image rendering context. When provided, it overrides auto-resolution (see [Path handling](#path-handling)) |

### Configuration options

| Option             | Default                 | Description                                                              |
|--------------------|-------------------------|--------------------------------------------------------------------------|
| `api_key`          | `ENV["OG_PILOT_API_KEY"]` | Your OG Pilot API key                                                   |
| `domain`           | `ENV["OG_PILOT_DOMAIN"]`  | Your domain registered with OG Pilot                                    |
| `base_url`         | `https://ogpilot.com`   | OG Pilot API base URL                                                    |
| `open_timeout`     | `5`                     | Connection timeout in seconds                                            |
| `read_timeout`     | `10`                    | Read timeout in seconds                                                  |
| `strip_extensions` | `true`                  | When `true`, file extensions are stripped from resolved paths (see [Strip extensions](#strip-extensions)) |

### Ruby options

| Option    | Default | Description                                                              |
|-----------|---------|--------------------------------------------------------------------------|
| `json`    | `false` | When `true`, sends `Accept: application/json` and parses the JSON response. On failure, returns `{ "image_url" => nil }` |
| `headers` | —       | Additional HTTP headers to include with the request                      |
| `default` | `false` | Forces `path` to `/` when `true`, unless a manual `path` is provided (see [Path handling](#path-handling)) |

### Template-specific parameters

| Template    | Parameters                                                                         |
|-------------|------------------------------------------------------------------------------------|
| `page`      | `title`, `description`                                                             |
| `blog_post` | `title`, `author_name`, `author_avatar_url`, `publish_date` (ISO 8601)             |
| `podcast`   | `title`, `episode_date` (ISO 8601)                                                 |
| `product`   | `title`, `unique_selling_point`                                                    |
| `event`     | `title`, `event_date`, `event_location`                                            |
| `book`      | `title`, `description`, `book_author`, `book_series_number`, `book_description`, `book_genre` |
| `portfolio` | `title`                                                                            |
| `company`   | `title`, `company_logo_url`, `description` (note: `image_url` is ignored)          |

### Path handling

The `path` parameter enhances OG Pilot analytics by tracking which OG images perform better across different pages on your site. Without it, all analytics would be aggregated under the `/` path, making it difficult to understand how individual pages or content types are performing. By automatically capturing the request path, you get granular insights into click-through rates and engagement for each OG image.

The client automatically injects a `path` parameter on every request:

| Option           | Behavior                                                                                                                                                               |
|------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `default: false` | Uses the current request path when available. In Rails, prefers `request.fullpath` (via the per-request store), then falls back to Rack/CGI env vars (`REQUEST_URI`, `PATH_INFO`). If no path can be determined, uses `/`. |
| `default: true`  | Forces the `path` parameter to `/`, regardless of the current request (unless `path` is provided explicitly).                                                           |
| `path: "/..."`   | Uses the provided path verbatim (normalized to start with `/`), overriding auto-resolution.                                                                             |

**Example:**

```ruby
image_url = OgPilotRuby.create_image(
  template: "blog_post",
  title: "How to Build Amazing OG Images",
  default: true
)
```

Manual override:

```ruby
image_url = OgPilotRuby.create_image(
  template: "page",
  title: "Hello OG Pilot",
  path: "/pricing?plan=pro"
)
```

Fetch JSON metadata instead:

```ruby
payload = {
  template: "page",
  title: "Hello OG Pilot"
}

data = OgPilotRuby.create_image(**payload, json: true)
```

### Strip extensions

When `strip_extensions` is enabled, the client removes file extensions from the
last segment of every resolved path. This ensures that `/docs`, `/docs.md`,
`/docs.php`, and `/docs.html` all resolve to `"/docs"`, so analytics are
consolidated under a single path regardless of the URL extension.

Multiple extensions are also stripped (`/archive.tar.gz` becomes `/archive`).
Dotfiles like `/.hidden` are left unchanged. Query strings are preserved.

```ruby
OgPilotRuby.configure do |config|
  config.strip_extensions = true
end

# All of these resolve to path "/docs":
OgPilotRuby.create_image(title: "Docs", path: "/docs")
OgPilotRuby.create_image(title: "Docs", path: "/docs.md")
OgPilotRuby.create_image(title: "Docs", path: "/docs.php")

# Nested paths work too: /blog/my-post.html → /blog/my-post
# Query strings are preserved: /docs.md?ref=main → /docs?ref=main
# Dotfiles are unchanged: /.hidden stays /.hidden
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
