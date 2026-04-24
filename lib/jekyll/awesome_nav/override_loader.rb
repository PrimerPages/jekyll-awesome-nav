# frozen_string_literal: true

require "yaml"

module Jekyll
  module AwesomeNav
    class OverrideLoader
      def initialize(site:, config:)
        @site = site
        @config = config
      end

      def load
        pattern = File.join(@site.source, @config.root_dir, "**", @config.nav_filename)

        Dir.glob(pattern).each_with_object({}) do |file, memo|
          dir = Utils.normalize_dir(Utils.relative_dir(@site.source, File.dirname(file)))
          items = load_file(file)
          memo[dir] = items if items
        end
      end

      private

      def load_file(file)
        data = YAML.safe_load_file(file, permitted_classes: [], aliases: false)
        raise Error, "expected an array of navigation items" unless data.is_a?(Array)

        data.map.with_index do |item, index|
          normalize_item(item, file, (index + 1).to_s)
        end
      rescue Psych::Exception, Error => e
        Jekyll.logger.warn("AwesomeNav:", "Could not load #{file}: #{e.message}")
        nil
      end

      def normalize_item(item, file, index_label)
        raise Error, "item #{index_label} in #{file} must be a mapping" unless item.is_a?(Hash)

        title = item["title"].to_s.strip
        raise Error, "item #{index_label} in #{file} is missing a title" if title.empty?

        children = normalize_children(item, file, index_label)
        url = normalized_url(item)
        dir = dir_for(url)

        Node.new(type: children.empty? ? :page : :section, dir: dir, title: title, url: url, children: children)
      end

      def normalize_children(item, file, index_label)
        return [] unless item["children"]

        raise Error, "children for item #{index_label} in #{file} must be an array" unless item["children"].is_a?(Array)

        item["children"].map.with_index do |child, child_index|
          normalize_item(child, file, "#{index_label}.#{child_index + 1}")
        end
      end

      def normalized_url(item)
        return nil unless item.key?("url")

        value = item["url"].to_s.strip
        return nil if value.empty?

        Utils.normalize_url(value)
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
