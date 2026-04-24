---
title: Documentation
---

This demo shows how `jekyll-awesome-nav` turns a normal folder of Markdown files into navigation data your layouts can render.

The plugin does not require collections. It reads pages under the configured `awesome_nav.root`, builds a tree, and writes the result onto each docs page.

## Start here

- [Getting Started]({{ "/docs/getting-started/" | relative_url }}) shows the minimum install and config.
- [Layout Integration]({{ "/docs/guides/layouts/" | relative_url }}) shows how to render sidebars, breadcrumbs, and previous/next links.
- [Configuration]({{ "/docs/guides/config/" | relative_url }}) explains the available plugin settings.
- [Navigation Overrides]({{ "/docs/guides/overrides/" | relative_url }}) shows how a local `_nav.yml` replaces one section.
- [Generated Data]({{ "/docs/guides/data/" | relative_url }}) lists the page variables available to themes and layouts.

## Folder shape

This demo uses a plain `docs/` folder:

```text
docs/
├── index.md
├── getting-started.md
└── guides/
    ├── index.md
    ├── install.md
    ├── config.md
    └── _nav.yml
```

Pages are included in the generated tree when they live under `awesome_nav.root`. A folder can provide an `index.md` page to represent the section itself.
