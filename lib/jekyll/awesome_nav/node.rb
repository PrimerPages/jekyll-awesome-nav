# frozen_string_literal: true

module Jekyll
  module AwesomeNav
    class Node
      attr_accessor :title, :url, :path, :filename
      attr_reader :type, :dir, :children

      def self.section(dir:, title: nil, url: nil, children: [], path: nil, filename: nil)
        new(type: :section, dir: dir, title: title, url: url, children: children, path: path, filename: filename)
      end

      def self.page(dir:, title:, url:, path: nil, filename: nil)
        new(type: :page, dir: dir, title: title, url: url, children: [], path: path, filename: filename)
      end

      def initialize(type:, dir:, title:, url:, children:, path: nil, filename: nil)
        @type = type
        @dir = dir
        @title = title
        @url = url
        @children = Array(children)
        @path = path
        @filename = filename
      end

      def section?
        type == :section
      end

      def page?
        type == :page
      end

      def with_children(children)
        self.class.new(type: type, dir: dir, title: title, url: url, children: children, path: path, filename: filename)
      end

      def deep_dup
        with_children(children.map(&:deep_dup))
      end
    end
  end
end
