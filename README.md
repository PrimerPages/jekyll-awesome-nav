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
- `page.awesome_nav_previous`: the previous linked nav item, when one exists
- `page.awesome_nav_next`: the next linked nav item, when one exists

The same data is also exposed on `site.config` as `awesome_nav_tree`, `awesome_nav_local_map`, and
`awesome_nav_files`.

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
- directory paths insert the generated directory section at that position
- glob entries expand generated pages or directories using Ruby's stdlib glob matching
- external URLs are preserved
- override order is preserved exactly as written
- manual sections are preserved as grouping sections unless they intentionally wrap the current directory

Useful glob examples:

```yaml
nav:
  - "*"
  - "*.md"
  - "*/"
  - "**/*.md"
  - glob: "*"
```

Recursive glob entries such as `**/*.md` are inserted as a flat list at that position. They do not preserve
the matched files' directory nesting.

Use manual sections to group items without linking the group itself:

```yaml
nav:
  - Main:
      - getting-started.md
      - guides
  - More Resources:
      - Website: https://example.com
```

Use `append_unmatched` to append generated local items that were not matched by the manual nav. Child `.nav.yml`
files inherit the closest parent setting unless they set their own value:

```yaml
append_unmatched: true
nav:
  - getting-started.md
  - guides
```

Use `sort` to order generated batches from glob entries and `append_unmatched`. Manual entries stay in the order
you write them:

```yaml
sort:
  direction: asc
  type: natural
  by: filename
  sections: last
  ignore_case: true
nav:
  - intro.md
  - "*.md"
```

`sort` is a file-level option. Per-glob options such as `- glob: "*"` with nested `sort:` are not currently
supported.

Use `ignore` to exclude generated items from glob entries and `append_unmatched`. Manual entries are still honored
when you list them explicitly:

```yaml
ignore:
  - "*.hidden.md"
  - drafts/
nav:
  - visible.md
  - "*.md"
```

Use `hide` in a directory's `.nav.yml` to keep that directory out of generated batches, explicit directory
references, and child nav-file processing:

```yaml
hide: true
```

Options-only `.nav.yml` files are valid, so a hidden directory does not need a `nav:` array.

## Documentation Site

The source for the plugin documentation site lives in [`site/`](site). From the gem root, run:

```sh
bundle exec jekyll serve --source site
```

The docs site renders `page.awesome_nav`, `page.awesome_nav_local`, `page.breadcrumbs`, and previous/next links
through a small layout in `site/_layouts/awesome_nav_demo.html`.

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
