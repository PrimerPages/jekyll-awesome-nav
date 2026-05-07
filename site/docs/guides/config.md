---
title: Configuration
---

Configure the plugin in `_config.yml`.

```yaml
awesome_nav:
  enabled: true
  root: docs
  nav_filename: .nav.yml
  include:
    - "**/*.md"
    - "**/*.html"
    - "**/*.htm"
  ignore:
    - "assets/**"
```

## Options

| Option | Default | Description |
| --- | --- | --- |
| `enabled` | `true` | Turns generation on or off. |
| `root` | `docs` | Folder that contains your documentation pages. |
| `nav_filename` | `.nav.yml` | Filename used for local subtree overrides. |
| `include` | `["**/*.md", "**/*.html", "**/*.htm"]` | Source path globs eligible for nav generation. |
| `ignore` | `["assets/**"]` | Source path globs excluded from nav generation. |

`include` is evaluated first, then `ignore` removes matches.

## Page titles

Generated items use page front matter when it is available:

```yaml
---
title: Configuration
nav_title: Config
---
```

Use `title` for the page heading and `nav_title` when the navigation label should be shorter.

## URLs

Jekyll controls the final page URL. The plugin reads those URLs from generated pages, so settings like `permalink: pretty` work normally.
