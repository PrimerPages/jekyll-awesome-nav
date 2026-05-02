# frozen_string_literal: true

require "yaml"

module Jekyll
  module AwesomeNav
    class NavFileLoader
      def initialize(site:, config:)
        @site = site
        @config = config
        @page_urls_by_path = build_page_url_index
      end

      def load
        pattern = File.join(@site.source, @config.root_dir, "**", @config.nav_filename)

        Dir.glob(pattern).each_with_object({}) do |file, memo|
          dir = Utils.normalize_dir(Utils.relative_dir(@site.source, File.dirname(file)))
          items = load_file(file, dir)
          memo[dir] = items if items
        end
      end

      private

      def load_file(file, dir)
        data = YAML.safe_load_file(file, permitted_classes: [], aliases: false)
        raise Error, "expected a mapping with a nav array" unless data.is_a?(Hash)

        nav = data["nav"]
        raise Error, "expected nav to be an array" unless nav.is_a?(Array)

        nav.map.with_index do |item, index|
          normalize_item(item, file, dir, (index + 1).to_s)
        end
      rescue Psych::Exception, Error => e
        Jekyll.logger.warn("AwesomeNav:", "Could not load #{file}: #{e.message}")
        nil
      end

      def normalize_item(item, file, dir, index_label)
        case item
        when Hash
          normalize_mapping(item, file, dir, index_label)
        when String
          title = title_for_path(item)
          source_path = resolved_source_path(item, dir)
          url = resolved_url_for_source_path(item, source_path)
          Node.page(dir: dir_for(url), title: title, url: url, path: source_path, filename: File.basename(source_path))
        else
          raise Error, "item #{index_label} in #{file} must be a mapping or path string"
        end
      end

      def normalize_mapping(item, file, dir, index_label)
        raise Error, "item #{index_label} in #{file} must have exactly one entry" unless item.length == 1

        title, value = item.first
        title = title.to_s.strip
        raise Error, "item #{index_label} in #{file} is missing a title" if title.empty?

        case value
        when Array
          children = value.map.with_index do |child, child_index|
            normalize_item(child, file, dir, "#{index_label}.#{child_index + 1}")
          end
          section_url = section_url_for(dir) || children.first&.url
          section_path = source_path_for_section(dir)
          Node.section(
            dir: dir_for(section_url),
            title: title,
            url: section_url,
            children: children,
            path: section_path,
            filename: File.basename(section_path)
          )
        when String
          source_path = resolved_source_path(value, dir)
          url = resolved_url_for_source_path(value, source_path)
          Node.page(dir: dir_for(url), title: title, url: url, path: source_path, filename: File.basename(source_path))
        else
          raise Error, "value for item #{index_label} in #{file} must be a path or array"
        end
      end

      def build_page_url_index
        @site.pages.each_with_object({}) do |page, index|
          [page.path, page.relative_path, page.instance_variable_get(:@relative_path)].compact.each do |path|
            normalized = Utils.normalize_dir(path)
            index[normalized] = Utils.normalize_url(page.url)
            index[without_index(normalized)] = Utils.normalize_url(page.url) if Utils.index_page?(page)
          end
        end
      end

      def resolved_source_path(value, dir)
        value = value.to_s.strip
        raise Error, "navigation path cannot be empty" if value.empty?
        return value if Utils.external_url?(value)

        source_path_for(value, dir)
      end

      def resolved_url_for_source_path(value, source_path)
        return value if Utils.external_url?(value)

        @page_urls_by_path.fetch(source_path) { fallback_url_for(source_path) }
      end

      def source_path_for(value, dir)
        clean_value = Utils.normalize_dir(value)
        candidates = []
        candidates << Utils.normalize_dir(File.join(dir, clean_value)) unless dir.empty?
        candidates << Utils.normalize_dir(File.join(@config.root_dir, clean_value))
        candidates << clean_value

        candidates.find { |candidate| @page_urls_by_path.key?(candidate) } || candidates.first
      end

      def fallback_url_for(source_path)
        without_extension = source_path.sub(%r{\.[^./]+\z}, "")
        Utils.normalize_url(without_index(without_extension))
      end

      def section_url_for(dir)
        normalized = Utils.normalize_dir(dir)
        @page_urls_by_path[normalized] || @page_urls_by_path[File.join(normalized, "index.md")]
      end

      def source_path_for_section(dir)
        normalized = Utils.normalize_dir(dir)
        [File.join(normalized, "index.md"), normalized].find { |candidate| @page_urls_by_path.key?(candidate) } || normalized
      end

      def without_index(path)
        path.sub(%r{(^|/)index(\.[^./]+)?\z}, "")
      end

      def title_for_path(path)
        Utils.titleize(File.basename(path, File.extname(path)))
      end

      def dir_for(url)
        return nil unless url
        return nil if Utils.external_url?(url)

        path = Utils.normalize_url(url).sub(%r{\A/}, "").sub(%r{/\z}, "")
        return "" if path.empty?

        segments = path.split("/")
        File.extname(segments.last).empty? ? segments.join("/") : segments[0...-1].join("/")
      end
    end
  end
end
