---
title: Documentation
---

These docs show how `jekyll-awesome-nav` turns a normal folder of Markdown files into navigation data your layouts can render.

The plugin does not require collections. It reads pages under the configured `awesome_nav.root`, builds a tree, and writes the result onto each docs page.

## Start here

- [Getting Started]({{ "/docs/getting-started/" | relative_url }}) shows the minimum install and config.
- [Examples]({{ "/docs/examples/" | relative_url }}) shows a few concrete folder and `.nav.yml` setups.
- [Layout Integration]({{ "/docs/guides/layouts/" | relative_url }}) shows how to render sidebars, breadcrumbs, and previous/next links.
- [Configuration]({{ "/docs/guides/config/" | relative_url }}) explains the available plugin settings.
- [.nav.yml Reference]({{ "/docs/guides/nav-file/" | relative_url }}) documents override syntax, options, and common patterns.
- [Navigation Overrides]({{ "/docs/guides/overrides/" | relative_url }}) shows how local `.nav.yml` files customize sections.
- [Generated Data]({{ "/docs/guides/data/" | relative_url }}) lists the page variables available to themes and layouts.

## Folder shape

This documentation site uses a plain `docs/` folder:

```text
docs/
├── index.md
├── examples/
│   ├── index.md
│   ├── basic-folder-navigation.md
│   └── local-override.md
├── getting-started.md
└── guides/
    ├── index.md
    ├── install.md
    ├── layouts.md
    ├── nav-file.md
    ├── overrides.md
    ├── data.md
    ├── config.md
    └── .nav.yml
```

Pages are included in the generated tree when they live under `awesome_nav.root`. A folder can provide an `index.md` page to represent the section itself.
