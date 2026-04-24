# frozen_string_literal: true

module Jekyll
  module AwesomeNav
    class Generator < Jekyll::Generator
      safe true
      priority :low

      def generate(site)
        config = Config.new(site.config["awesome_nav"])
        return unless config.enabled?

        pages = PageSet.new(site, config)
        return if pages.empty?

        tree = TreeBuilder.new(pages: pages, root_dir: config.root_dir).build
        overrides = OverrideLoader.new(site: site, config: config).load
        resolved_tree = OverrideResolver.new(root_dir: config.root_dir, override_map: overrides).apply(tree, config.root_dir)
        result = NavigationResult.new(
          tree: resolved_tree,
          root_dir: config.root_dir,
          root_page: pages.root_page,
          override_map: overrides
        )

        pages.each do |page|
          page_dir = Utils.source_dir_for(page)
          page_url = Utils.normalize_url(page.url)
          page.data["awesome_nav"] = deep_copy(result.serialized_tree)
          page.data["awesome_nav_local"] = deep_copy(result.local_nav_for(page_dir))
          page.data["awesome_nav_dir"] = result.nav_dir_for(page_dir)
          page.data["breadcrumbs"] = result.breadcrumbs_for(page)
          page.data["awesome_nav_previous"] = deep_copy(result.nav_entry_for(page_url)&.fetch("previous", nil))
          page.data["awesome_nav_next"] = deep_copy(result.nav_entry_for(page_url)&.fetch("next", nil))
        end

        site.config["awesome_nav_tree"] = deep_copy(result.serialized_tree)
        site.config["awesome_nav_local_map"] = deep_copy(result.serialized_local_nav_map)
        site.config["awesome_nav_overrides"] = deep_copy(result.serialized_overrides)
      end

      private

      def deep_copy(value)
        Marshal.load(Marshal.dump(value))
      end
    end
  end
end
