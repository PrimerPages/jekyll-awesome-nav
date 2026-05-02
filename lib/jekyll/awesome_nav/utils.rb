# frozen_string_literal: true

module Jekyll
  module AwesomeNav
    module Utils
      module_function

      def normalize_dir(dir)
        dir.to_s.strip.sub(%r{\A/+}, "").sub(%r{/+\z}, "")
      end

      def path_segments(dir)
        normalize_dir(dir).split("/").reject(&:empty?)
      end

      def parent_dir(dir)
        segments = path_segments(dir)
        return "" if segments.length <= 1

        segments[0...-1].join("/")
      end

      def last_segment(path)
        path_segments(path).last.to_s
      end

      def relative_to_root(dir, root_dir)
        return "" if dir == root_dir
        return dir.delete_prefix("#{root_dir}/") if dir.start_with?("#{root_dir}/")

        dir
      end

      def relative_dir(source, absolute_dir)
        absolute_dir
          .sub(%r{\A#{Regexp.escape(source)}/?}, "")
          .sub(%r{\A/+}, "")
          .sub(%r{/+\z}, "")
      end

      def external_url?(value)
        value.to_s.match?(%r{\A([a-z][a-z0-9+\-.]*:)?//}i)
      end

      def normalize_url(url)
        value = url.to_s.strip
        return "/" if value.empty?
        return value if external_url?(value)

        value = "/#{value}" unless value.start_with?("/")
        value = value.sub(/index\.html\z/, "")
        value = value.gsub(%r{/+}, "/")
        value = "#{value}/" if File.extname(value).empty? && !value.end_with?("/")
        value
      end

      def titleize(value)
        value.to_s
             .tr("_-", " ")
             .split
             .map { |part| part[0] ? "#{part[0].upcase}#{part[1..]}" : part }
             .join(" ")
      end

      def index_page?(page)
        File.basename(page.path, File.extname(page.path)) == "index"
      end

      def source_dir_for(page)
        path = source_path_for(page)
        dir = File.dirname(path.to_s)
        normalize_dir(dir == "." ? "" : dir)
      end

      def source_path_for(page)
        path =
          if page.respond_to?(:relative_path) && !page.relative_path.nil?
            page.relative_path
          else
            page.path
          end

        normalize_dir(path)
      end

      def page_title(page, basename)
        page.data["nav_title"] || page.data["title"] || titleize(basename)
      end
    end
  end
end
