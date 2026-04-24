# AGENTS.md

## Overview

This project implements a Jekyll plugin that provides **folder-based navigation with automatic generation and local overrides**, modeled after MkDocs Material + Awesome Pages behavior.

The plugin builds a **full navigation tree from a configured root directory**, and allows **per-folder `_nav.yml` files to override subtrees**.

---

## Core Design Principles

1. **Convention over configuration**

   * Navigation should work with zero config.
   * Folder structure defines navigation by default.

2. **Local control**

   * A `_nav.yml` file in a folder overrides navigation for that folder only.

3. **Predictability**

   * No merging or implicit behavior.
   * Overrides are explicit and replace-only.

4. **Full-tree navigation**

   * Always render the full navigation tree from the root.
   * Expand current section in UI (handled by theme).

5. **Separation of concerns**

   * Plugin generates data.
   * Theme handles rendering.

---

## Configuration

Defined in `_config.yml`:

```yaml
awesome_nav:
  enabled: true
  root: docs
  nav_filename: _nav.yml
```

### Fields

* `enabled` (bool): enable/disable plugin
* `root` (string): root directory for navigation
* `nav_filename` (string): name of override file (default `_nav.yml`)

---

## Navigation Behavior

### 1. Automatic Navigation Generation

* Navigation is generated from `site.pages` under `root`
* Folder structure determines hierarchy
* Each directory becomes a section
* Each page becomes a leaf node

Rules:

* `index.md` defines:

  * section title (fallback: folder name)
  * section URL
* Other pages:

  * become leaf items under their directory
* Titles:

  * `nav_title` → `title` → filename fallback

---

### 2. Full Tree Model

* A single navigation tree is built from the root
* Every page receives the same tree (`page.awesome_nav`)
* Tree structure is consistent across all pages

---

### 3. Override Behavior (`_nav.yml`)

* `_nav.yml` overrides navigation for its directory subtree
* Override replaces generated subtree entirely
* No merging with parent or generated structure

Resolution:

* While building final tree:

  * if directory has `_nav.yml`, use it
  * otherwise use generated structure

---

### 4. Override Scope

* Overrides apply only to their directory
* Parent and sibling sections remain unchanged
* Overrides cascade downward (children inherit overridden subtree)

---

### 5. No Override Case

* If no `_nav.yml` exists anywhere:

  * navigation is fully auto-generated

---

## Data Exposed to Pages

Each page receives:

### `page.awesome_nav`

* Full navigation tree (root-based, with overrides applied)

### `page.awesome_nav_local`

* Local subtree for the page’s directory

### `page.awesome_nav_dir`

* Directory that provided the active nav (override or root)

### `page.breadcrumbs`

* Array of breadcrumb items:

  ```yaml
  - title: Guides
    url: /docs/guides/
  - title: Install
    url: /docs/guides/install/
  ```

---

## Breadcrumb Behavior

* Derived from the final navigation tree
* Matches the path to the current page
* Uses nav titles (not filesystem names)

---

## File Structure Expectations

Example:

```text
docs/
  index.md
  getting-started.md
  guides/
    install.md
    config.md
```

Optional overrides:

```text
docs/_nav.yml
docs/guides/_nav.yml
```

---

## `_nav.yml` Format

```yaml
- title: Guides
  url: /docs/guides/
  children:
    - title: Install
      url: /docs/guides/install/
    - title: Config
      url: /docs/guides/config/
```

Rules:

* Must be an array of items
* Each item:

  * `title` (required)
  * `url` (optional)
  * `children` (optional, recursive)

---

## URL Handling

* URLs normalized to:

  * leading slash
  * trailing slash for directories
* `index.html` stripped
* Matching is done on normalized URLs

---

## Sorting Rules

Generated navigation:

1. Sections before pages
2. Alphabetical by title

Override navigation:

* Order is preserved exactly as written

---

## Page Inclusion Rules

* Only include pages under `root`
* Exclude `_nav.yml` files from page list
* Ignore pages outside root entirely

---

## Internal Implementation Notes

* Plugin type: `Jekyll::Generator`
* Runs after site inventory
* Does not modify Jekyll collections
* Works only with `site.pages`

### Key Steps

1. Collect pages under root
2. Build generated tree
3. Load `_nav.yml` overrides
4. Apply overrides to tree (replace subtree)
5. Assign navigation + breadcrumbs to pages

---

## Non-Goals

* No support for:

  * merging nav structures
  * multiple nav roots
  * dynamic runtime nav generation
  * collection integration
* No UI rendering logic in plugin

---

## Future Extensions (Optional)

* `nav_title` override in front matter
* Hidden pages (`nav_exclude`)
* Ordering via front matter
* Collapsible state hints
* Multiple roots

---

## Summary

This plugin provides:

* Automatic navigation from folder structure
* Full-tree sidebar navigation
* Local override via `_nav.yml`
* Breadcrumb generation

Design is intentionally:

* simple
* predictable
* aligned with MkDocs-style workflows
