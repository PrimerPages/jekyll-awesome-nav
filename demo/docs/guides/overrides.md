---
title: Navigation Overrides
---

By default, the plugin builds navigation from files and folders. A local `.nav.yml` lets a folder replace its own subtree.

This demo has an override at `docs/guides/.nav.yml`:

```yaml
nav:
  - Guides Hub: index.md
  - Install Guide: install.md
  - Layout Integration: layouts.md
  - Configuration: config.md
```

## When to use an override

Use `.nav.yml` when a section needs:

- a custom order
- shorter or clearer labels
- links that do not map one-to-one with filenames
- a curated subset of pages

## What gets replaced

An override replaces the subtree for the directory where it appears. Other directories still use generated navigation.

For example, `docs/guides/.nav.yml` controls the guides section only. The root `docs/` tree is still generated from the folder structure and then uses the guides override for that branch.

## Link format

Each item uses a `Title: path.md` entry. Nested sections use a list:

```yaml
nav:
  - Section:
      - Page: section/page.md
```

Use Markdown source paths. The plugin resolves them through Jekyll pages and then uses the final page URL.
