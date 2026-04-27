# Jekyll Awesome Nav

`jekyll-awesome-nav` builds a full navigation tree from a folder hierarchy and lets any directory replace its subtree with a local `.nav.yml` file.

The plugin is designed around the behavior described in [AGENTS.md](AGENTS.md):

- navigation is generated from `site.pages` under one configured root
- directories become sections and pages become leaves
- `index.md` sets a section title and URL
- `.nav.yml` replaces a directory subtree without merging
- every page under the root gets the same full tree plus local subtree data

## Installation

Add the gem to your Jekyll site's `Gemfile`:

```ruby
gem "jekyll-awesome-nav"
```

Then enable it in `_config.yml`:

```yaml
plugins:
  - jekyll-awesome-nav

awesome_nav:
  enabled: true
  root: docs
  nav_filename: .nav.yml
```

## Exposed Page Data

Each page under the configured root receives:

- `page.awesome_nav`: the full navigation tree rooted at `awesome_nav.root`
- `page.awesome_nav_local`: the local subtree for the page's directory
- `page.awesome_nav_dir`: the directory supplying the active nav context
- `page.breadcrumbs`: breadcrumb items derived from the final tree

Titles resolve in this order:

1. `nav_title`
2. `title`
3. filename fallback

## `.nav.yml` Format

Overrides use a top-level `nav:` entry:

```yaml
nav:
  - Guides: index.md
  - Install: install.md
  - Config: config.md
```

Override item rules:

- paths are resolved through `site.pages`
- relative paths are resolved from the `.nav.yml` directory first, then from `awesome_nav.root`
- external URLs are preserved
- override order is preserved exactly as written

## Demo

A small example site lives in [`demo/`](demo). From the gem root, run:

```sh
bundle exec jekyll serve --source demo
```

The demo layout prints `page.awesome_nav`, `page.awesome_nav_local`, and `page.breadcrumbs` so you can inspect the generated data directly.

## Development

Install dependencies and run the test suite:

```sh
bundle install
bundle exec rake test
```

You can also open an interactive console with:

```sh
bin/console
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
