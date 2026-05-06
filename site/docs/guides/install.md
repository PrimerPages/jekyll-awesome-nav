---
title: Install
---

This page appears under the overridden guides subtree.

## Gemfile

Add the plugin to your site's `Gemfile`:

```ruby
gem "jekyll-awesome-nav"
```

If you use a `:jekyll_plugins` group, it is fine to place it there:

```ruby
group :jekyll_plugins do
  gem "jekyll-awesome-nav"
end
```

## Jekyll config

Add the plugin to `_config.yml`:

```yaml
plugins:
  - jekyll-awesome-nav
```

Then configure the docs root:

```yaml
awesome_nav:
  enabled: true
  root: docs
  nav_filename: .nav.yml
```

## Layout default

Set a layout for the docs folder so every generated page receives the same navigation UI:

```yaml
defaults:
  - scope:
      path: "docs"
    values:
      layout: awesome_nav_demo
```

The plugin generates the data. The layout decides how that data looks.
