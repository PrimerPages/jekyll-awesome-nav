# frozen_string_literal: true

module Jekyll
  module AwesomeNav
    class PageSet
      include Enumerable

      def initialize(site, config)
        @pages = site.pages.select do |page|
          next false if File.basename(page.path) == config.nav_filename

          dir = Utils.source_dir_for(page)
          dir == config.root_dir || dir.start_with?("#{config.root_dir}/")
        end
        @root_dir = config.root_dir
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
    end
  end
end
