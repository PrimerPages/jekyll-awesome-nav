# frozen_string_literal: true

module Jekyll
  module AwesomeNav
    class NavResolver
      ResolutionContext = Struct.new(:append_unmatched, :sort_options, :ignore_patterns, keyword_init: true)

      def initialize(root_dir:, nav_map:)
        @root_dir = root_dir
        @nav_map = nav_map
        @generated_by_dir = {}
        @generated_by_path = {}
      end

      def apply(
        items,
        current_dir = @root_dir,
        inherited_append_unmatched: false,
        inherited_sort_options: SortOptions.from(nil),
        inherited_ignore_patterns: []
      )
        index_generated(items)
        generated_items = generated_children_for(current_dir, items)
        nav_file = @nav_map[current_dir]
        options = nav_options(nav_file)
        override_items = nav_items(nav_file)
        context = ResolutionContext.new(
          append_unmatched: options.append_unmatched_or(inherited_append_unmatched),
          sort_options: options.sort_options_or(inherited_sort_options),
          ignore_patterns: options.ignore_patterns_or(inherited_ignore_patterns)
        )

        return resolve_generated_items(generated_items, current_dir, context) unless override_items

        matched = {}
        resolved = expand_override_items(override_items, current_dir, generated_items, context, matched)
        return resolved.first.children if same_dir_wrapper?(resolved, current_dir)
        return resolved unless context.append_unmatched

        resolved + unmatched_items(generated_items, matched, context, current_dir)
      end

      def resolved_nav_dir(page_dir)
        current = page_dir

        loop do
          return current if @nav_map.key?(current)
          return @root_dir if current == @root_dir
          break if current.empty?

          current = Utils.parent_dir(current)
        end

        @root_dir
      end

      private

      def index_generated(items)
        Array(items).each do |item|
          @generated_by_dir[Utils.normalize_dir(item.dir)] = item if item.section? && item.dir
          @generated_by_path[Utils.normalize_dir(item.path)] = item if item.path
          index_generated(item.children)
        end
      end

      def generated_children_for(current_dir, fallback_items)
        return fallback_items if current_dir == @root_dir

        @generated_by_dir.fetch(current_dir, Node.section(dir: current_dir)).children
      end

      def nav_items(nav_file)
        return nil unless nav_file
        return nav_file.items if nav_file.respond_to?(:items)

        nav_file
      end

      def nav_options(nav_file)
        return NavFileOptions.new unless nav_file
        return nav_file.options if nav_file.respond_to?(:options)

        NavFileOptions.new
      end

      def same_dir_wrapper?(items, current_dir)
        items.length == 1 && items.first.section? && Utils.normalize_dir(items.first.dir) == current_dir
      end

      def raw_same_dir_wrapper?(current_dir)
        same_dir_wrapper?(Array(nav_items(@nav_map[current_dir])), current_dir)
      end

      def expand_override_items(items, current_dir, generated_items, context, matched)
        Array(items).flat_map do |item|
          expand_item(item, current_dir, generated_items, context, matched)
        end
      end

      def expand_item(item, current_dir, generated_items, context, matched)
        return expand_reference(item, current_dir, generated_items, context, matched) if item.reference?

        applied_item = item.deep_dup
        item_dir = child_dir_for_item(current_dir, applied_item)
        mark_matched(applied_item, matched)

        if applied_item.section? && item_dir == current_dir
          return [resolve_local_section(applied_item, current_dir, generated_items, context, matched)]
        end

        if applied_item.section? && item_dir.nil?
          if same_dir_manual_wrapper?(applied_item, current_dir)
            return [resolve_local_section(same_dir_section(applied_item, current_dir), current_dir, generated_items, context, matched)]
          end

          return [resolve_manual_section(applied_item, current_dir, generated_items, context, matched)]
        end

        applied_item = with_resolved_children(applied_item, item_dir, context) if item_dir && item_dir != current_dir

        [applied_item]
      end

      def resolve_local_section(item, current_dir, generated_items, context, matched)
        child_matched = {}
        children = expand_override_items(item.children, current_dir, generated_items, context, child_matched)
        children += unmatched_items(generated_items, child_matched, context, current_dir) if context.append_unmatched
        child_matched.each_key { |key| matched[key] = true }

        Node.section(
          dir: item.dir,
          title: item.title,
          url: item.url,
          children: children,
          path: item.path,
          filename: item.filename
        )
      end

      def expand_reference(item, current_dir, generated_items, context, matched)
        return expand_glob(item, current_dir, generated_items, context, matched) if glob?(item.target)

        generated = generated_node_for_reference(item, current_dir)
        return [] unless generated
        return [] if hidden?(generated)

        return [section_page_node(generated, item.title)] if generated.section? && Utils.normalize_dir(generated.dir) == current_dir

        node = generated.deep_dup
        node.title = item.title if item.title
        mark_matched(node, matched)
        [with_resolved_children(node, Utils.normalize_dir(node.dir), context)]
      end

      def section_page_node(section, title)
        Node.page(
          dir: section.dir,
          title: title || section.title,
          url: section.url,
          path: section.path,
          filename: section.filename
        )
      end

      def expand_glob(item, current_dir, generated_items, context, matched)
        glob_matches(item.target, current_dir, generated_items, context).filter_map do |generated|
          next if matched?(generated, matched)

          node = generated.deep_dup
          mark_matched(node, matched)
          with_resolved_children(node, Utils.normalize_dir(node.dir), context)
        end
      end

      def with_resolved_children(item, item_dir, context)
        return item unless item.section?

        children = apply(
          item.children,
          item_dir,
          inherited_append_unmatched: context.append_unmatched,
          inherited_sort_options: context.sort_options,
          inherited_ignore_patterns: context.ignore_patterns
        )
        Node.section(
          dir: item.dir,
          title: item.title,
          url: item.url,
          children: children,
          path: item.path,
          filename: item.filename
        )
      end

      def resolve_generated_items(items, current_dir, context)
        Array(items).flat_map do |item|
          applied_item = item.deep_dup
          item_dir = child_dir_for_item(current_dir, applied_item)

          next if hidden?(applied_item)
          next resolve_generated_child(applied_item, item_dir, context) if item_dir && item_dir != current_dir

          applied_item
        end
      end

      def resolve_generated_child(item, item_dir, context)
        return with_resolved_children(item, item_dir, context) unless @nav_map.key?(item_dir)
        return with_resolved_children(item, item_dir, context) if raw_same_dir_wrapper?(item_dir)

        apply(
          item.children,
          item_dir,
          inherited_append_unmatched: context.append_unmatched,
          inherited_sort_options: context.sort_options,
          inherited_ignore_patterns: context.ignore_patterns
        )
      end

      def unmatched_items(generated_items, matched, context, current_dir)
        context.sort_options.sort(generated_items).filter_map do |item|
          next if matched?(item, matched)
          next if hidden?(item)
          next if ignored?(item, current_dir, context.ignore_patterns)

          node = item.deep_dup
          with_resolved_children(node, Utils.normalize_dir(node.dir), context)
        end
      end

      def generated_node_for_reference(item, current_dir)
        candidates_for(item.target, current_dir).each do |candidate|
          page = @generated_by_path[candidate]
          return page if page

          section = @generated_by_dir[candidate]
          return section if section
        end

        nil
      end

      def candidates_for(value, current_dir)
        clean_value = Utils.normalize_dir(value)
        candidates = []
        candidates << Utils.normalize_dir(File.join(current_dir, clean_value)) unless current_dir.empty?
        candidates << Utils.normalize_dir(File.join(@root_dir, clean_value))
        candidates << clean_value
        candidates
      end

      def glob_matches(pattern, current_dir, generated_items, context)
        recursive = pattern.to_s.include?("**")
        directory_only = pattern.to_s.end_with?("/")
        normalized_pattern = pattern.to_s.delete_suffix("/")

        pool = recursive ? flatten_generated(generated_items) : Array(generated_items)
        matches = pool.select do |item|
          next false if directory_only && !item.section?
          next false if hidden?(item)
          next false if ignored?(item, current_dir, context.ignore_patterns)

          File.fnmatch?(normalized_pattern, relative_match_path(item, current_dir), File::FNM_PATHNAME)
        end
        context.sort_options.sort(matches)
      end

      def hidden?(item)
        item_dir = hidden_dir_for(item)
        nav_file = @nav_map[item_dir]

        nav_file.respond_to?(:options) && nav_file.options.hide?
      end

      def hidden_dir_for(item)
        item.section? ? Utils.normalize_dir(item.dir) : Utils.source_dir_for_path(item.path)
      end

      def ignored?(item, current_dir, ignore_patterns)
        match_path = relative_match_path(item, current_dir)
        ignore_patterns.any? do |pattern|
          normalized_pattern = pattern.to_s.delete_suffix("/")
          File.fnmatch?(normalized_pattern, match_path, File::FNM_PATHNAME)
        end
      end

      def flatten_generated(items)
        Array(items).each_with_object([]) do |item, flattened|
          next if hidden?(item)

          flattened << item
          flattened.concat(flatten_generated(item.children)) if item.section?
        end
      end

      def relative_match_path(item, current_dir)
        source = item.section? ? Utils.normalize_dir(item.dir) : Utils.normalize_dir(item.path)
        Utils.relative_to_root(source, current_dir)
      end

      def glob?(value)
        value.to_s.match?(/[*?\[]/)
      end

      def mark_matched(item, matched)
        return if item.reference?

        matched[node_key(item)] = true
        item.children.each { |child| mark_matched(child, matched) } if item.section?
      end

      def matched?(item, matched)
        matched[node_key(item)]
      end

      def node_key(item)
        item.section? ? "dir:#{Utils.normalize_dir(item.dir)}" : "path:#{Utils.normalize_dir(item.path || item.url)}"
      end

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
