# frozen_string_literal: true

module Jekyll
  module AwesomeNav
    class Generator < Jekyll::Generator
      safe true
      # Run after low-priority generators (for example jekyll-readme-index),
      # so synthetic pages are present before nav data assignment.
      priority :lowest

      def generate(site)
        config = Config.new(site.config["awesome_nav"])
        return unless config.enabled?

        pages = PageSet.new(site, config)
        return if pages.empty?

        result = build_navigation_result(site, config, pages)
        assign_page_navigation(pages, result)
        assign_site_navigation(site, result)
      end

      private

      def build_navigation_result(site, config, pages)
        tree = TreeBuilder.new(pages: pages, root_dir: config.root_dir).build
        nav_map = NavFileLoader.new(site: site, config: config).load
        resolved_tree = NavResolver.new(
          root_dir: config.root_dir,
          nav_map: nav_map,
          root_page: pages.root_page
        ).apply(tree, config.root_dir)

        NavigationResult.new(
          tree: resolved_tree,
          root_dir: config.root_dir,
          root_page: pages.root_page,
          nav_map: nav_map
        )
      end

      def assign_page_navigation(pages, result)
        pages.each do |page|
          page_dir = Utils.source_dir_for(page)
          nav_dir = result.nav_dir_for(page_dir)
          page_url = Utils.normalize_url(page.url)
          page_entry = result.nav_entry_for(page_url)

          page.data["awesome_nav"] = deep_copy(result.annotated_tree_for(page_url))
          page.data["awesome_nav_local"] = deep_copy(result.local_nav_for(nav_dir))
          page.data["awesome_nav_dir"] = nav_dir
          page.data["breadcrumbs"] = result.breadcrumbs_for(page)
          page.data["awesome_nav_previous"] = deep_copy(page_entry&.fetch("previous", nil))
          page.data["awesome_nav_next"] = deep_copy(page_entry&.fetch("next", nil))
        end
      end

      def assign_site_navigation(site, result)
        site.config["awesome_nav_tree"] = deep_copy(result.serialized_tree)
        site.config["awesome_nav_local_map"] = deep_copy(result.serialized_local_nav_map)
        site.config["awesome_nav_files"] = deep_copy(result.serialized_nav_files)
      end

      def deep_copy(value)
        Marshal.load(Marshal.dump(value))
      end
    end
  end
end
