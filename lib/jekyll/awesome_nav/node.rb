# frozen_string_literal: true

module Jekyll
  module AwesomeNav
    class Node
      attr_accessor :title, :url
      attr_reader :type, :dir, :children

      def self.section(dir:, title: nil, url: nil, children: [])
        new(type: :section, dir: dir, title: title, url: url, children: children)
      end

      def self.page(dir:, title:, url:)
        new(type: :page, dir: dir, title: title, url: url, children: [])
      end

      def initialize(type:, dir:, title:, url:, children:)
        @type = type
        @dir = dir
        @title = title
        @url = url
        @children = Array(children)
      end

      def section?
        type == :section
      end

      def page?
        type == :page
      end

      def with_children(children)
        self.class.new(type: type, dir: dir, title: title, url: url, children: children)
      end

      def deep_dup
        with_children(children.map(&:deep_dup))
      end
    end
  end
end
