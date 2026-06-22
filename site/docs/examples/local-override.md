---
title: Local Override Example
---

Add a `.nav.yml` file when one folder needs a curated order or friendlier labels.

```text
docs/
└── guides/
    ├── .nav.yml
    ├── index.md
    ├── install.md
    └── config.md
```

Example override:

```yaml
nav:
  - Guides Home: index.md
  - Install Guide: install.md
  - Configuration: config.md
```

That file replaces the generated navigation for `docs/guides/` only. The rest of the docs tree still uses normal folder-based generation.
