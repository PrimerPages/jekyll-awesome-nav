---
title: .nav.yml Reference
---

`.nav.yml` lets a directory replace its generated navigation subtree with a hand-authored one.

Put the file in the directory you want to control:

```text
docs/
  guides/
    .nav.yml
    index.md
    install.md
    config.md
```

The override applies only to that directory subtree. Parent sections and sibling sections keep using their own generated or overridden navigation.

## Minimal file

The smallest useful `.nav.yml` defines a `nav:` array:

```yaml
nav:
  - Guides Home: index.md
  - Install: install.md
  - Configuration: config.md
```

Each item is either:

- a string path like `install.md`
- a titled path mapping like `Install: install.md`
- a titled section with nested children
- a glob entry such as `"*.md"`

## Top-level options

These keys are supported at the top level of `.nav.yml`:

| Option | Type | Description |
| --- | --- | --- |
| `nav` | array | Manual nav entries for this directory. |
| `append_unmatched` | boolean | Appends generated items that were not matched by `nav`. |
| `ignore` | string or array | Excludes generated items from globs and `append_unmatched`. |
| `sort` | mapping | Sorts generated batches from globs and `append_unmatched`. |
| `hide` | boolean | Hides this directory from generated nav, manual directory references, and child nav processing. |

Options-only files are valid, so this works when you only want to hide a directory:

```yaml
hide: true
```

## `nav` items

### String paths

Use a string when you want the generated page or section title:

```yaml
nav:
  - index.md
  - install.md
  - guides
```

- File paths insert a page.
- Directory paths insert that directory's generated section.
- External URLs are allowed and stay as-is.

### Titled paths

Use a mapping to rename an item in navigation:

```yaml
nav:
  - Guides Hub: index.md
  - Install Guide: install.md
  - Project Website: https://example.com
```

### Manual sections

Use a titled list to create a group:

```yaml
nav:
  - Main:
      - getting-started.md
      - Guides: guides
  - More:
      - API Reference: ../reference.md
      - Project Website: https://example.com
```

Manual sections are grouping nodes. They do not get their own URL unless you point them at a page instead of a child list.

## Path resolution

Paths are resolved in this order:

1. Relative to the directory that contains the `.nav.yml`
2. Relative to `awesome_nav.root`

That means a file in `docs/guides/.nav.yml` can usually use short local paths like `install.md`, while a shared page can still be referenced from the root, such as `reference.md`.

## Globs

Globs pull in generated items without listing each one manually:

```yaml
nav:
  - getting-started.md
  - "*.md"
  - "*/"
  - "archive/**/*.md"
```

Useful patterns:

- `"*.md"` matches pages in the current directory
- `"*/"` matches child sections only
- `"**/*.md"` matches pages recursively

Recursive globs insert matches as a flat list at that position. They do not preserve nested folder structure.

You can also write a glob entry explicitly:

```yaml
nav:
  - glob: "*.md"
```

## `append_unmatched`

By default, a manual `nav:` array is a complete replacement for the local generated subtree. Items you leave out stay out.

Set `append_unmatched: true` when you want to hand-place a few items and then append the rest of the generated local items afterward:

```yaml
append_unmatched: true
nav:
  - getting-started.md
  - guides
```

Child `.nav.yml` files inherit the nearest parent `append_unmatched` setting unless they set their own value.

## `ignore`

`ignore` filters generated items from:

- glob matches
- appended unmatched items

It does not block a page you list explicitly in `nav:`.

```yaml
ignore:
  - "*.hidden.md"
  - "drafts/"
nav:
  - visible.md
  - "*.md"
```

Here, `visible.md` still appears even if it also matches an ignore pattern, because it was added manually.

## `sort`

`sort` controls the order of generated batches only:

- glob expansions
- `append_unmatched` output

Manual entries stay in the exact order you wrote them.

```yaml
sort:
  direction: desc
  type: natural
  by: filename
  sections: last
  ignore_case: true
nav:
  - intro.md
  - "*.md"
```

Supported sort fields:

| Key | Values | Default |
| --- | --- | --- |
| `direction` | `asc`, `desc` | `asc` |
| `type` | `alphabetical`, `natural` | `alphabetical` |
| `by` | `path`, `filename`, `title` | `path` |
| `sections` | `first`, `last` | `first` |
| `ignore_case` | `true`, `false` | `true` |

Per-glob sort settings are not supported. Sorting is configured once for the whole file.

## `hide`

Use `hide: true` in a directory's own `.nav.yml` when that subtree should disappear from navigation entirely:

```yaml
hide: true
```

When a directory is hidden:

- it is skipped in generated navigation
- manual references to that directory do not insert it
- child `.nav.yml` files under that directory are not used

## Common patterns

### Curated local section

```yaml
nav:
  - Guides Home: index.md
  - Install: install.md
  - Configuration: config.md
```

### Manual intro, generated remainder

```yaml
append_unmatched: true
nav:
  - index.md
  - getting-started.md
```

### Rename a section and include its generated children

```yaml
nav:
  - User Guides: guides
```

### Group links under headings

```yaml
nav:
  - Learn:
      - getting-started.md
      - guides
  - External:
      - API Docs: https://example.com/api
```

## Notes

- `.nav.yml` replaces the local subtree. It does not merge with generated items unless you opt into `append_unmatched`.
- Duplicate items are automatically deduplicated when a manual entry and a glob point at the same generated source.
- Paths must resolve to pages or directories already known to Jekyll under the configured root.
