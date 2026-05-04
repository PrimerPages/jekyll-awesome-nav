---
title: Getting Started
---

Add the gem to your Jekyll site and enable it in `_config.yml`.

## Install the gem

```ruby
gem "jekyll-awesome-nav"
```

Then install your bundle:

```bash
bundle install
```

## Enable the plugin

```yaml
plugins:
  - jekyll-awesome-nav

awesome_nav:
  enabled: true
  root: docs
  nav_filename: .nav.yml
```

## Add docs pages

Create Markdown files under the configured root:

```text
docs/
├── index.md
├── getting-started.md
└── guides/
    ├── index.md
    └── install.md
```

Each page should have a title:

```markdown
---
title: Install
---

Install instructions go here.
```

The plugin builds navigation from these pages during the normal Jekyll build. Your layout can then render `page.awesome_nav`, `page.breadcrumbs`, and the previous/next links.

## Render it

If your theme already supports `jekyll-awesome-nav`, choose that docs layout for pages under your docs root. This site uses its docs layout through defaults:

```yaml
defaults:
  - scope:
      path: "docs"
    values:
      layout: docs
```

If your theme does not support it yet, use the examples in [Layout Integration]({{ "/docs/guides/layouts/" | relative_url }}) to wire the data into your own layout.
