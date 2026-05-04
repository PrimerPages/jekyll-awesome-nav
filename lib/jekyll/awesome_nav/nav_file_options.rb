# frozen_string_literal: true

module Jekyll
  module AwesomeNav
    class NavFileOptions
      UNSET = Object.new.freeze

      attr_reader :ignore_patterns, :sort_options

      def self.from(data)
        new(
          append_unmatched: data.key?("append_unmatched") ? data["append_unmatched"] : UNSET,
          ignore: data.key?("ignore") ? data["ignore"] : UNSET,
          sort: data.key?("sort") ? data["sort"] : UNSET
        )
      end

      def initialize(append_unmatched: UNSET, ignore: UNSET, sort: UNSET)
        @append_unmatched = append_unmatched
        @ignore_patterns = ignore == UNSET ? UNSET : normalize_ignore_patterns(ignore)
        @sort_options = sort == UNSET ? UNSET : SortOptions.from(sort)
      end

      def append_unmatched_or(inherited)
        return inherited if @append_unmatched == UNSET

        !!@append_unmatched
      end

      def ignore_patterns_or(inherited)
        return inherited if @ignore_patterns == UNSET

        @ignore_patterns
      end

      def sort_options_or(inherited)
        return inherited if @sort_options == UNSET

        @sort_options
      end

      private

      def normalize_ignore_patterns(value)
        patterns =
          case value
          when String
            [value]
          when Array
            value
          else
            raise Error, "ignore must be a path string or array of path strings"
          end

        patterns.map do |pattern|
          raise Error, "ignore patterns must be path strings" unless pattern.is_a?(String)

          pattern
        end
      end
    end
  end
end
