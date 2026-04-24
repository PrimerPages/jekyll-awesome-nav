# frozen_string_literal: true

require "yaml"

module Jekyll
  module AwesomeNav
    class Generator < Jekyll::Generator
      safe true
      priority :low

      DEFAULT_CONFIG = {
        "enabled" => true,
        "root" => "docs",
        "nav_filename" => "_nav.yml"
      }.freeze

      def generate(site)
        config = normalized_config(site)
        return unless config["enabled"]

        pages = nav_pages(site, config)
        return if pages.empty?

        root_dir = normalize_dir(config["root"])
        root_page = pages.find { |page| source_dir_for(page) == root_dir && index_page?(page) }
        generated_tree = build_generated_tree(pages, root_dir)
        override_map = load_override_map(site, config)
        final_tree_with_meta = apply_overrides(generated_tree, override_map, root_dir)
        local_nav_map = build_local_nav_map(final_tree_with_meta, root_dir)
        final_tree = strip_internal_keys(final_tree_with_meta)
        clean_local_nav_map = strip_internal_keys(local_nav_map)
        nav_neighbors = build_nav_neighbors(final_tree, root_page, root_dir)

        pages.each do |page|
          page_dir = source_dir_for(page)
          page_url = normalize_url(page.url)
          page.data["awesome_nav"] = deep_copy(final_tree)
          page.data["awesome_nav_local"] = deep_copy(clean_local_nav_map.fetch(page_dir, []))
          page.data["awesome_nav_dir"] = resolved_nav_dir(page_dir, override_map, root_dir)
          page.data["breadcrumbs"] = build_breadcrumbs(page, final_tree, root_dir, root_page)
          page.data["awesome_nav_previous"] = deep_copy(nav_neighbors.dig(page_url, "previous"))
          page.data["awesome_nav_next"] = deep_copy(nav_neighbors.dig(page_url, "next"))
        end

        site.config["awesome_nav_tree"] = deep_copy(final_tree)
        site.config["awesome_nav_local_map"] = deep_copy(clean_local_nav_map)
        site.config["awesome_nav_overrides"] = deep_copy(strip_internal_keys(override_map))
      end

      private

      def normalized_config(site)
        DEFAULT_CONFIG.merge(site.config["awesome_nav"] || {})
      end

      def nav_pages(site, config)
        root_dir = normalize_dir(config["root"])
        nav_filename = config["nav_filename"]

        site.pages.select do |page|
          next false if File.basename(page.path) == nav_filename

          dir = source_dir_for(page)
          dir == root_dir || dir.start_with?("#{root_dir}/")
        end
      end

      def build_generated_tree(pages, root_dir)
        root = section_node(root_dir, nil, nil)
        pages.each { |page| add_page_to_tree(root, page, root_dir) }
        sort_section!(root)
        section_children_to_items(root)
      end

      def section_node(dir, title, url)
        {
          "__type" => "section",
          "__dir" => dir,
          "title" => title,
          "url" => url,
          "children" => {}
        }
      end

      def add_page_to_tree(root, page, root_dir)
        dir = source_dir_for(page)
        relative_dir = relative_to_root(dir, root_dir)
        current = root
        current_dir = root_dir

        path_segments(relative_dir).each do |segment|
          current_dir = [current_dir, segment].reject(&:empty?).join("/")
          current["children"][segment] ||= section_node(current_dir, titleize(segment), nil)
          current = current["children"][segment]
        end

        basename = File.basename(page.path, File.extname(page.path))
        title = page_title(page, basename)
        url = normalize_url(page.url)

        if basename == "index"
          current["title"] = title
          current["url"] = url
        else
          current["children"][basename] = {
            "__type" => "page",
            "__dir" => [dir, basename].reject(&:empty?).join("/"),
            "title" => title,
            "url" => url
          }
        end
      end

      def page_title(page, basename)
        page.data["nav_title"] || page.data["title"] || titleize(basename)
      end

      def sort_section!(section)
        return unless section["children"].is_a?(Hash)

        section["children"] = section["children"]
          .sort_by { |_key, child| sort_key(child) }
          .to_h

        section["children"].each_value do |child|
          sort_section!(child) if child["__type"] == "section"
        end
      end

      def sort_key(child)
        [
          child["__type"] == "section" ? 0 : 1,
          child["title"].to_s.downcase
        ]
      end

      def section_children_to_items(section)
        section["children"].each_value.map do |child|
          if child["__type"] == "section"
            item = {
              "title" => child["title"] || titleize(last_segment(child["__dir"])),
              "__dir" => child["__dir"]
            }
            item["url"] = child["url"] if child["url"]

            children = section_children_to_items(child)
            item["children"] = children unless children.empty?
            item
          else
            {
              "title" => child["title"],
              "url" => child["url"],
              "__dir" => child["__dir"]
            }
          end
        end
      end

      def load_override_map(site, config)
        nav_filename = config["nav_filename"]
        overrides_root = File.join(site.source, config["root"])
        pattern = File.join(overrides_root, "**", nav_filename)

        Dir.glob(pattern).each_with_object({}) do |file, memo|
          dir = relative_dir(site.source, File.dirname(file))
          items = load_override_file(file)
          memo[normalize_dir(dir)] = items if items
        end
      end

      def load_override_file(file)
        data = YAML.safe_load_file(file, permitted_classes: [], aliases: false)
        unless data.is_a?(Array)
          raise Error, "expected an array of navigation items"
        end

        data.map.with_index do |item, index|
          normalize_override_item(item, file, (index + 1).to_s)
        end
      rescue StandardError => e
        Jekyll.logger.warn("AwesomeNav:", "Could not load #{file}: #{e.message}")
        nil
      end

      def normalize_override_item(item, file, index_label)
        unless item.is_a?(Hash)
          raise Error, "item #{index_label} in #{file} must be a mapping"
        end

        title = item["title"].to_s.strip
        raise Error, "item #{index_label} in #{file} is missing a title" if title.empty?

        normalized = { "title" => title }
        normalized["url"] = normalize_url(item["url"]) if item.key?("url") && !item["url"].to_s.strip.empty?

        if item["children"]
          unless item["children"].is_a?(Array)
            raise Error, "children for item #{index_label} in #{file} must be an array"
          end

          normalized["children"] = item["children"].map.with_index do |child, child_index|
            normalize_override_item(child, file, "#{index_label}.#{child_index + 1}")
          end
        end

        normalized["__dir"] = dir_for_override_item(normalized)
        normalized
      end

      def dir_for_override_item(item)
        return nil unless item["url"]

        return nil if external_url?(item["url"])

        path = normalize_url(item["url"]).sub(%r{\A/}, "").sub(%r{/\z}, "")
        return "" if path.empty?

        segments = path.split("/")
        File.extname(segments.last).empty? ? segments.join("/") : segments[0...-1].join("/")
      end

      def apply_overrides(items, override_map, current_dir)
        source_items = override_map.fetch(current_dir, items)

        Array(source_items).flat_map do |item|
          applied_item = deep_copy(item)
          item_dir = child_dir_for_item(current_dir, applied_item)

          if item_dir && item_dir != current_dir && override_map.key?(item_dir)
            apply_overrides(override_map[item_dir], override_map, item_dir)
          else
            if applied_item["children"].is_a?(Array) && item_dir && item_dir != current_dir
              applied_item["__dir"] ||= item_dir
              applied_item["children"] = apply_overrides(applied_item["children"], override_map, item_dir)
            end

            [applied_item]
          end
        end
      end

      def child_dir_for_item(parent_dir, item)
        return normalize_dir(item["__dir"]) if item["__dir"]
        return nil unless item["url"]

        dir = dir_for_override_item(item)
        return nil if dir.nil? || dir.empty?

        if dir == parent_dir || dir.start_with?("#{parent_dir}/")
          normalize_dir(dir)
        else
          normalize_dir([parent_dir, last_segment(dir)].reject(&:empty?).join("/"))
        end
      end

      def build_local_nav_map(tree, root_dir)
        map = {}
        map[root_dir] = deep_copy(tree)
        walk_local_nav_map(tree, map)
        map
      end

      def walk_local_nav_map(items, map)
        Array(items).each do |item|
          next unless item["children"].is_a?(Array)

          dir = normalize_dir(item["__dir"])
          next if dir.empty?

          map[dir] = deep_copy(item["children"])
          walk_local_nav_map(item["children"], map)
        end
      end

      def build_breadcrumbs(page, tree, root_dir, root_page)
        page_url = normalize_url(page.url)
        trail = find_trail(tree, page_url)
        return root_breadcrumb(page, root_dir) if trail.nil? && source_dir_for(page) == root_dir && index_page?(page)
        return [] unless trail

        breadcrumbs = trail.filter_map do |item|
          next if item["title"].to_s.empty?

          crumb = { "title" => item["title"] }
          crumb["url"] = item["url"] if item["url"]
          crumb
        end

        prepend_root_breadcrumb(root_dir, root_page, breadcrumbs)
      end

      def root_breadcrumb(page, root_dir)
        title = page.data["nav_title"] || page.data["title"] || titleize(last_segment(root_dir))
        [{ "title" => title, "url" => normalize_url(page.url) }]
      end

      def prepend_root_breadcrumb(root_dir, root_page, breadcrumbs)
        root_crumb = {
          "title" => root_page&.data&.fetch("nav_title", nil) || root_page&.data&.fetch("title", nil) || titleize(last_segment(root_dir)),
          "url" => normalize_url(root_page&.url || "/#{root_dir}/")
        }

        return breadcrumbs if breadcrumbs.first == root_crumb

        [root_crumb] + breadcrumbs
      end

      def build_nav_neighbors(tree, root_page, root_dir)
        items = []

        if root_page
          items << {
            "title" => root_page.data["nav_title"] || root_page.data["title"] || titleize(last_segment(root_dir)),
            "url" => normalize_url(root_page.url)
          }
        end

        items.concat(flatten_nav_items(tree))

        items.each_with_index.each_with_object({}) do |(item, index), neighbors|
          neighbors[item["url"]] = {
            "previous" => index.positive? ? deep_copy(items[index - 1]) : nil,
            "next" => index < items.length - 1 ? deep_copy(items[index + 1]) : nil
          }
        end
      end

      def flatten_nav_items(items)
        Array(items).each_with_object([]) do |item, flattened|
          flattened << { "title" => item["title"], "url" => item["url"] } if item["url"]
          flattened.concat(flatten_nav_items(item["children"])) if item["children"].is_a?(Array)
        end
      end

      def find_trail(items, target_url, trail = [])
        Array(items).each do |item|
          current_trail = trail + [item]
          return current_trail if item["url"] && normalize_url(item["url"]) == target_url

          next unless item["children"].is_a?(Array)

          found = find_trail(item["children"], target_url, current_trail)
          return found if found
        end

        nil
      end

      def resolved_nav_dir(page_dir, override_map, root_dir)
        current = page_dir

        loop do
          return current if override_map.key?(current)
          return root_dir if current == root_dir
          break if current.empty?

          current = parent_dir(current)
        end

        root_dir
      end

      def strip_internal_keys(value)
        case value
        when Array
          value.map { |item| strip_internal_keys(item) }
        when Hash
          value.each_with_object({}) do |(key, item), cleaned|
            next if key.start_with?("__")

            cleaned[key] = strip_internal_keys(item)
          end
        else
          value
        end
      end

      def deep_copy(value)
        Marshal.load(Marshal.dump(value))
      end

      def index_page?(page)
        File.basename(page.path, File.extname(page.path)) == "index"
      end

      def source_dir_for(page)
        path =
          if page.respond_to?(:relative_path) && !page.relative_path.nil?
            page.relative_path
          else
            page.path
          end

        dir = File.dirname(path.to_s)
        normalize_dir(dir == "." ? "" : dir)
      end

      def path_segments(dir)
        normalize_dir(dir).split("/").reject(&:empty?)
      end

      def relative_to_root(dir, root_dir)
        return "" if dir == root_dir
        return dir.delete_prefix("#{root_dir}/") if dir.start_with?("#{root_dir}/")

        dir
      end

      def relative_dir(source, absolute_dir)
        absolute_dir
          .sub(/\A#{Regexp.escape(source)}\/?/, "")
          .sub(%r{\A/+}, "")
          .sub(%r{/+\z}, "")
      end

      def normalize_dir(dir)
        dir.to_s.strip.sub(%r{\A/+}, "").sub(%r{/+\z}, "")
      end

      def parent_dir(dir)
        segments = path_segments(dir)
        return "" if segments.length <= 1

        segments[0...-1].join("/")
      end

      def normalize_url(url)
        value = url.to_s.strip
        return "/" if value.empty?
        return value if external_url?(value)

        value = "/#{value}" unless value.start_with?("/")
        value = value.sub(%r{index\.html\z}, "")
        value = value.gsub(%r{/+}, "/")
        value = "#{value}/" if File.extname(value).empty? && !value.end_with?("/")
        value
      end

      def external_url?(value)
        value.to_s.match?(%r{\A([a-z][a-z0-9+\-.]*:)?//}i)
      end

      def titleize(value)
        value.to_s
          .tr("_-", " ")
          .split
          .map { |part| part[0] ? "#{part[0].upcase}#{part[1..]}" : part }
          .join(" ")
      end

      def last_segment(path)
        path_segments(path).last.to_s
      end
    end
  end
end
