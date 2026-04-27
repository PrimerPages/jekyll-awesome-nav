---
layout: profile
title: Jekyll Awesome Nav
permalink: /
links:
  - name: Browse the demo docs
    url: /docs/
    octicon: file
  - name: Install the gem
    url: /docs/getting-started/
    octicon: package
  - name: View the source
    url: https://github.com/PrimerPages/jekyll-awesome-nav
    octicon: mark-github
  - name: Read the README
    url: https://github.com/PrimerPages/jekyll-awesome-nav/blob/main/README.md
    octicon: book
---

# Folder-based docs navigation for Jekyll

`jekyll-awesome-nav` builds a full navigation tree from your docs folder and lets any directory replace its own subtree with a local `.nav.yml` file.

It is designed for documentation sites that want sensible defaults from folder structure, while still giving authors precise local control when a section needs a custom order or grouping.

## What it does

- Builds navigation from `site.pages` under one configured root such as `docs/`
- Uses `index.md` as the section title and section URL
- Exposes the full tree on every page as `page.awesome_nav`
- Exposes the current directory subtree as `page.awesome_nav_local`
- Computes breadcrumbs from the final resolved tree
- Replaces a directory subtree entirely when `.nav.yml` is present

## Quick start

Add the gem to your site:

```ruby
gem "jekyll-awesome-nav"
```

Enable it in `_config.yml`:

```yaml
plugins:
  - jekyll-awesome-nav

awesome_nav:
  enabled: true
  root: docs
  nav_filename: .nav.yml
```

Then create docs pages under `docs/`. If you want a section to use a custom structure, add a local `.nav.yml` in that folder.

## This site

This demo site doubles as the plugin info site. The docs section on this site demonstrates:

- automatically generated navigation
- a local `.nav.yml` override in `docs/guides/`
- breadcrumb generation
- per-page `awesome_nav` data for theme rendering
 
