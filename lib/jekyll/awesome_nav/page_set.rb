# frozen_string_literal: true

module Jekyll
  module AwesomeNav
    class PageSet
      include Enumerable

      def initialize(site, config)
        root_dir = config.root_dir
        include_patterns = config.include_patterns
        ignore_patterns = config.ignore_patterns
        @pages = site.pages.select do |page|
          source_path = Utils.source_path_for(page)

          next false if File.basename(page.path) == config.nav_filename
          next false unless included?(source_path, include_patterns)
          next false if ignored?(source_path, ignore_patterns)

          dir = Utils.source_dir_for(page)
          root_dir.empty? || dir == root_dir || dir.start_with?("#{root_dir}/")
        end
        @root_dir = root_dir
      end

      def each(&block)
        @pages.each(&block)
      end

      def empty?
        @pages.empty?
      end

      def root_page
        @pages.find { |page| Utils.source_dir_for(page) == @root_dir && Utils.index_page?(page) }
      end

      def ignored?(source_path, patterns)
        patterns.any? do |pattern|
          File.fnmatch?(pattern, source_path, File::FNM_PATHNAME | File::FNM_DOTMATCH)
        end
      end

      def included?(source_path, patterns)
        return true if patterns.nil?

        patterns.any? do |pattern|
          File.fnmatch?(pattern, source_path, File::FNM_PATHNAME | File::FNM_DOTMATCH)
        end
      end
    end
  end
end
