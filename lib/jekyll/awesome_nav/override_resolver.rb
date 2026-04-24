# frozen_string_literal: true

module Jekyll
  module AwesomeNav
    class OverrideResolver
      def initialize(root_dir:, override_map:)
        @root_dir = root_dir
        @override_map = override_map
      end

      def apply(items, current_dir = @root_dir)
        source_items = @override_map.fetch(current_dir, items)

        Array(source_items).flat_map do |item|
          applied_item = item.deep_dup
          item_dir = child_dir_for_item(current_dir, applied_item)

          if item_dir && item_dir != current_dir && @override_map.key?(item_dir)
            apply(@override_map[item_dir], item_dir)
          else
            if applied_item.section? && item_dir && item_dir != current_dir
              applied_item = Node.section(
                dir: applied_item.dir || item_dir,
                title: applied_item.title,
                url: applied_item.url,
                children: apply(applied_item.children, item_dir)
              )
            end

            [applied_item]
          end
        end
      end

      def resolved_nav_dir(page_dir)
        current = page_dir

        loop do
          return current if @override_map.key?(current)
          return @root_dir if current == @root_dir
          break if current.empty?

          current = Utils.parent_dir(current)
        end

        @root_dir
      end

      private

      def child_dir_for_item(parent_dir, item)
        return Utils.normalize_dir(item.dir) if item.dir
        return nil unless item.url

        dir = dir_for_item(item)
        return nil if dir.nil? || dir.empty?

        if dir == parent_dir || dir.start_with?("#{parent_dir}/")
          Utils.normalize_dir(dir)
        else
          Utils.normalize_dir([parent_dir, Utils.last_segment(dir)].reject(&:empty?).join("/"))
        end
      end

      def dir_for_item(item)
        return nil unless item.url
        return nil if Utils.external_url?(item.url)

        path = Utils.normalize_url(item.url).sub(%r{\A/}, "").sub(%r{/\z}, "")
        return "" if path.empty?

        segments = path.split("/")
        File.extname(segments.last).empty? ? segments.join("/") : segments[0...-1].join("/")
      end
    end
  end
end
