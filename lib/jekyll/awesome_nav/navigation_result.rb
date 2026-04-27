# frozen_string_literal: true

module Jekyll
  module AwesomeNav
    class NavigationResult
      def initialize(tree:, root_dir:, root_page:, nav_map:)
        @tree = tree
        @root_dir = root_dir
        @root_page = root_page
        @nav_map = nav_map
      end

      def serialized_tree
        @serialized_tree ||= Serializer.serialize_tree(@tree)
      end

      def serialized_local_nav_map
        @serialized_local_nav_map ||= Serializer.serialize_map(local_nav_nodes)
      end

      def serialized_nav_files
        @serialized_nav_files ||= Serializer.serialize_map(@nav_map)
      end

      def local_nav_for(page_dir)
        serialized_local_nav_map.fetch(page_dir, [])
      end

      def nav_dir_for(page_dir)
        current = page_dir

        loop do
          return current if @nav_map.key?(current)
          return @root_dir if current == @root_dir
          break if current.empty?

          current = Utils.parent_dir(current)
        end

        @root_dir
      end

      def breadcrumbs_for(page)
        page_url = Utils.normalize_url(page.url)
        trail = find_trail(serialized_tree, page_url)
        return root_breadcrumb(page) if trail.nil? && Utils.source_dir_for(page) == @root_dir && Utils.index_page?(page)
        return [] unless trail

        breadcrumbs = trail.filter_map do |item|
          next if item["title"].to_s.empty?

          crumb = { "title" => item["title"] }
          crumb["url"] = item["url"] if item["url"]
          crumb
        end

        prepend_root_breadcrumb(breadcrumbs)
      end

      def nav_entry_for(page_url)
        neighbor_map[page_url]
      end

      private

      def local_nav_nodes
        @local_nav_nodes ||= begin
          map = { @root_dir => @tree.map(&:deep_dup) }
          walk_local_nav_map(@tree, map)
          @nav_map.each do |dir, items|
            map[dir] = local_items_for_override(dir, items)
          end
          map
        end
      end

      def local_items_for_override(dir, items)
        return [] if items.empty?
        return items.first.children.map(&:deep_dup) if items.length == 1 && items.first.section? && Utils.normalize_dir(items.first.dir) == dir

        items.map(&:deep_dup)
      end

      def walk_local_nav_map(items, map)
        Array(items).each do |item|
          next unless item.section? && item.children.any?

          dir = Utils.normalize_dir(item.dir)
          next if dir.empty?

          map[dir] = item.children.map(&:deep_dup)
          walk_local_nav_map(item.children, map)
        end
      end

      def root_breadcrumb(page)
        title = page.data["nav_title"] || page.data["title"] || Utils.titleize(Utils.last_segment(@root_dir))
        [{ "title" => title, "url" => Utils.normalize_url(page.url) }]
      end

      def prepend_root_breadcrumb(breadcrumbs)
        root_crumb = {
          "title" => @root_page&.data&.fetch("nav_title",
                                             nil) || @root_page&.data&.fetch("title", nil) || Utils.titleize(Utils.last_segment(@root_dir)),
          "url" => Utils.normalize_url(@root_page&.url || "/#{@root_dir}/")
        }

        return breadcrumbs if breadcrumbs.first == root_crumb

        [root_crumb] + breadcrumbs
      end

      def neighbor_map
        @neighbor_map ||= begin
          items = []
          if @root_page
            items << {
              "title" => @root_page.data["nav_title"] || @root_page.data["title"] || Utils.titleize(Utils.last_segment(@root_dir)),
              "url" => Utils.normalize_url(@root_page.url)
            }
          end

          items.concat(flatten_nav_items(serialized_tree))

          items.each_with_index.with_object({}) do |(item, index), neighbors|
            neighbors[item["url"]] = {
              "previous" => index.positive? ? deep_copy(items[index - 1]) : nil,
              "next" => index < items.length - 1 ? deep_copy(items[index + 1]) : nil
            }
          end
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
          return current_trail if item["url"] && Utils.normalize_url(item["url"]) == target_url

          next unless item["children"].is_a?(Array)

          found = find_trail(item["children"], target_url, current_trail)
          return found if found
        end

        nil
      end

      def deep_copy(value)
        Marshal.load(Marshal.dump(value))
      end
    end
  end
end
