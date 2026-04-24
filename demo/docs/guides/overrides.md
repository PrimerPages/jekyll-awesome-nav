---
title: Navigation Overrides
---

By default, the plugin builds navigation from files and folders. A local `_nav.yml` lets a folder replace its own subtree.

This demo has an override at `docs/guides/_nav.yml`:

```yaml
- title: Guides Hub
  url: /docs/guides/
  children:
    - title: Install Guide
      url: /docs/guides/install/
    - title: Layout Integration
      url: /docs/guides/layouts/
    - title: Configuration
      url: /docs/guides/config/
```

## When to use an override

Use `_nav.yml` when a section needs:

- a custom order
- shorter or clearer labels
- links that do not map one-to-one with filenames
- a curated subset of pages

## What gets replaced

An override replaces the subtree for the directory where it appears. Other directories still use generated navigation.

For example, `docs/guides/_nav.yml` controls the guides section only. The root `docs/` tree is still generated from the folder structure and then uses the guides override for that branch.

## Link format

Each item needs a `title` and `url`. Child items go under `children`:

```yaml
- title: Section
  url: /docs/section/
  children:
    - title: Page
      url: /docs/section/page/
```

Use final Jekyll URLs, not filesystem paths.
