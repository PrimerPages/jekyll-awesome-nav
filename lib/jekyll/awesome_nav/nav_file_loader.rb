# frozen_string_literal: true

require "yaml"

module Jekyll
  module AwesomeNav
    class NavFileLoader
      OPTION_KEYS = %w[append_unmatched hide ignore sort].freeze

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
        raise Error, "expected a mapping" unless data.is_a?(Hash)

        nav = data["nav"]
        raise Error, "expected nav to be an array" if data.key?("nav") && !nav.is_a?(Array)
        raise Error, "expected nav to be an array or supported options" unless data.key?("nav") || options_only?(data)

        items = Array(nav).map.with_index do |item, index|
          normalize_item(item, file, dir, (index + 1).to_s)
        end
        NavFile.new(items: items, options: NavFileOptions.from(data))
      rescue Psych::Exception, Error => e
        Jekyll.logger.warn("AwesomeNav:", "Could not load #{file}: #{e.message}")
        nil
      end

      def options_only?(data)
        data.keys.any? { |key| OPTION_KEYS.include?(key.to_s) }
      end

      def normalize_item(item, file, dir, index_label)
        case item
        when Hash
          normalize_mapping(item, file, dir, index_label)
        when String
          normalize_string(item, dir)
        else
          raise Error, "item #{index_label} in #{file} must be a mapping or path string"
        end
      end

      def normalize_mapping(item, file, dir, index_label)
        raise Error, "item #{index_label} in #{file} must have exactly one entry" unless item.length == 1

        title, value = item.first
        return normalize_glob(value, dir, index_label, file) if title.to_s == "glob"

        title = title.to_s.strip
        raise Error, "item #{index_label} in #{file} is missing a title" if title.empty?

        case value
        when Array
          children = value.map.with_index do |child, child_index|
            normalize_item(child, file, dir, "#{index_label}.#{child_index + 1}")
          end
          Node.section(
            dir: nil,
            title: title,
            url: nil,
            children: children,
            path: nil,
            filename: nil
          )
        when String
          normalize_string(value, dir, title: title)
        else
          raise Error, "value for item #{index_label} in #{file} must be a path or array"
        end
      end

      def normalize_string(value, dir, title: nil)
        value = value.to_s.strip
        raise Error, "navigation path cannot be empty" if value.empty?

        return Node.page(dir: nil, title: title || value, url: value, path: value, filename: File.basename(value)) if Utils.external_url?(value)

        Node.reference(dir: dir, title: title, target: value)
      end

      def normalize_glob(value, dir, index_label, file)
        raise Error, "glob item #{index_label} in #{file} must be a path string" unless value.is_a?(String)

        normalize_string(value, dir)
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
