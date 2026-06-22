---
title: Basic Folder Navigation
---

Use plain folders and pages when you want navigation to come directly from the docs tree.

```text
docs/
├── index.md
├── getting-started.md
└── guides/
    ├── index.md
    ├── install.md
    └── config.md
```

With no `.nav.yml` files, the plugin turns that structure into sections and pages automatically.

```yaml
awesome_nav:
  enabled: true
  root: docs
  nav_filename: .nav.yml
```

This is a good default when the filesystem already reflects the order and grouping you want.
