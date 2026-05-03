# frozen_string_literal: true

module Jekyll
  module AwesomeNav
    class SortOptions
      DEFAULTS = {
        "direction" => "asc",
        "type" => "alphabetical",
        "by" => "path",
        "sections" => "first",
        "ignore_case" => true
      }.freeze

      def self.from(value)
        new(value)
      end

      def initialize(value)
        raise Error, "sort must be a mapping" unless value.nil? || value.is_a?(Hash)

        @data = DEFAULTS.merge(value || {})
      end

      def sort(items)
        sorted = Array(items).sort_by { |item| sort_key(item) }
        direction == "desc" ? sorted.reverse : sorted
      end

      private

      def sort_key(item)
        [
          section_rank(item),
          value_key(value_for(item))
        ]
      end

      def section_rank(item)
        case sections
        when "first"
          item.section? ? 0 : 1
        when "last"
          item.section? ? 1 : 0
        else
          0
        end
      end

      def value_key(value)
        value = value.to_s
        value = value.downcase if ignore_case?
        type == "natural" ? natural_key(value) : value
      end

      def natural_key(value)
        value.split(/(\d+)/).map { |part| part.match?(/\A\d+\z/) ? part.to_i : part }
      end

      def value_for(item)
        case by
        when "filename"
          item.filename || File.basename(item.path.to_s)
        when "title"
          item.title
        else
          item.path || item.dir || item.title
        end
      end

      def direction
        @data["direction"].to_s
      end

      def type
        @data["type"].to_s
      end

      def by
        @data["by"].to_s
      end

      def sections
        @data["sections"].to_s
      end

      def ignore_case?
        @data["ignore_case"] != false
      end
    end
  end
end
