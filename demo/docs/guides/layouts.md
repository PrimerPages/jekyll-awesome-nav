---
title: Layout Integration
---

`jekyll-awesome-nav` generates navigation data. Your layout renders it.

This demo uses its own small layout at `demo/_layouts/awesome_nav_demo.html`, with a recursive include at `demo/_includes/awesome-nav-demo-tree.html`.

You can use those files as a starting point when wiring the same data into another Jekyll theme.

## Enable a docs layout

Set a layout for every page under your docs root:

```yaml
defaults:
  - scope:
      path: "docs"
    values:
      layout: awesome_nav_demo
```

Inside that layout, check for generated navigation before rendering plugin-specific UI:

```liquid
{% raw %}{% if page.awesome_nav %}
  <!-- Render awesome nav UI -->
{% endif %}{% endraw %}
```

## Render breadcrumbs

The plugin writes breadcrumbs to `page.breadcrumbs`.

```liquid
{% raw %}{% if page.breadcrumbs %}
<nav aria-label="Breadcrumbs">
  <ol>
    {% for item in page.breadcrumbs %}
      <li><a href="{{ item.url | relative_url }}">{{ item.title }}</a></li>
    {% endfor %}
  </ol>
</nav>
{% endif %}{% endraw %}
```

## Render a sidebar

Use `page.awesome_nav` for the full docs tree:

```liquid
{% raw %}<nav aria-label="Documentation">
  <ul>
    {% for item in page.awesome_nav %}
      <li>
        <a href="{{ item.url | relative_url }}">{{ item.title }}</a>
        {% if item.children %}
          <ul>
            {% for child in item.children %}
              <li><a href="{{ child.url | relative_url }}">{{ child.title }}</a></li>
            {% endfor %}
          </ul>
        {% endif %}
      </li>
    {% endfor %}
  </ul>
</nav>{% endraw %}
```

For deeply nested docs, move the recursive portion into an include and call it for each `children` collection.

## Render the current section

Use `page.awesome_nav_local` when you want a compact menu for the current directory:

```liquid
{% raw %}{% if page.awesome_nav_local %}
<nav aria-label="This section">
  <ul>
    {% for item in page.awesome_nav_local %}
      <li><a href="{{ item.url | relative_url }}">{{ item.title }}</a></li>
    {% endfor %}
  </ul>
</nav>
{% endif %}{% endraw %}
```

## Render previous and next links

The plugin calculates previous and next pages from the final resolved tree, including local `_nav.yml` overrides.

```liquid
{% raw %}<nav aria-label="Pagination">
  {% if page.awesome_nav_previous %}
    <a href="{{ page.awesome_nav_previous.url | relative_url }}">
      Previous: {{ page.awesome_nav_previous.title }}
    </a>
  {% endif %}

  {% if page.awesome_nav_next %}
    <a href="{{ page.awesome_nav_next.url | relative_url }}">
      Next: {{ page.awesome_nav_next.title }}
    </a>
  {% endif %}
</nav>{% endraw %}
```

## Theme includes

If you maintain a theme, a clean pattern is:

- one include for breadcrumbs
- one recursive include for tree rendering
- one layout that chooses full-tree or local-section navigation

That keeps the plugin data plain and lets the theme own the HTML and CSS.
