---
title: Generated Data
---

The plugin writes navigation data onto each page under the configured docs root.

## Page variables

| Variable | Description |
| --- | --- |
| `page.awesome_nav` | Full resolved docs tree. |
| `page.awesome_nav_local` | Navigation items for the current directory context. |
| `page.awesome_nav_dir` | Directory that supplied the current local nav context. |
| `page.breadcrumbs` | Breadcrumb entries for the current page. |
| `page.awesome_nav_previous` | Previous page in the resolved navigation order. |
| `page.awesome_nav_next` | Next page in the resolved navigation order. |

## Tree item shape

Navigation entries are hashes with a title, URL, and optional children:

```yaml
title: Install Guide
url: /docs/guides/install/
children: []
```

Layouts should treat `children` as optional because leaf pages do not need nested items.

## Site variables

The plugin also writes resolved data into `site.config` for advanced theme use:

| Variable | Description |
| --- | --- |
| `site.awesome_nav_tree` | Full resolved tree. |
| `site.awesome_nav_local_map` | Local navigation lookup by directory. |
| `site.awesome_nav_overrides` | Loaded override data. |

Most layouts should prefer the `page.*` variables because they are already scoped to the current page.
