# frozen_string_literal: true

module Jekyll
  module AwesomeNav
    class Serializer
      def self.serialize_tree(nodes, include_internal: false)
        nodes = nodes.items if nodes.respond_to?(:items)
        Array(nodes).map { |node| serialize_node(node, include_internal: include_internal) }
      end

      def self.serialize_map(map, include_internal: false)
        map.each_with_object({}) do |(key, items), serialized|
          serialized[key] = serialize_tree(items, include_internal: include_internal)
        end
      end

      def self.serialize_node(node, include_internal: false)
        item = { "title" => node.title }
        item["url"] = node.url if node.url
        item["children"] = serialize_tree(node.children, include_internal: include_internal) if node.section? && node.children.any?
        item["__dir"] = node.dir if include_internal && node.dir
        item
      end
    end
  end
end
