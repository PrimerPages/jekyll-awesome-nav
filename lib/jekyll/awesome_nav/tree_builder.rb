# frozen_string_literal: true

module Jekyll
  module AwesomeNav
    class TreeBuilder
      def initialize(pages:, root_dir:)
        @pages = pages
        @root_dir = root_dir
      end

      def build
        root = Node.section(dir: @root_dir)
        @pages.each { |page| add_page(root, page) }
        root.children.sort_by! { |child| sort_key(child) }
        sort_sections(root.children)
      end

      private

      def add_page(root, page)
        page_path = Utils.source_path_for(page)
        dir = Utils.source_dir_for(page)
        relative_dir = Utils.relative_to_root(dir, @root_dir)
        current = root
        current_dir = @root_dir

        Utils.path_segments(relative_dir).each do |segment|
          current_dir = [current_dir, segment].reject(&:empty?).join("/")
          child = current.children.find { |node| node.section? && Utils.last_segment(node.dir) == segment }
          unless child
            child = Node.section(dir: current_dir, title: Utils.titleize(segment))
            current.children << child
          end
          current = child
        end

        basename = File.basename(page.path, File.extname(page.path))
        title = Utils.page_title(page, basename)
        url = Utils.normalize_url(page.url)

        if basename == "index"
          current.title = title
          current.url = url
          current.path = page_path
          current.filename = File.basename(page_path)
        else
          current.children << Node.page(
            dir: [dir, basename].reject(&:empty?).join("/"),
            title: title,
            url: url,
            path: page_path,
            filename: File.basename(page_path)
          )
        end
      end

      def sort_sections(items)
        items.each do |child|
          next unless child.section?

          child.children.sort_by! { |nested| sort_key(nested) }
          sort_sections(child.children)
        end
      end

      def sort_key(child)
        [
          child.section? ? 0 : 1,
          child.path.to_s.downcase,
          child.title.to_s.downcase
        ]
      end
    end
  end
end
