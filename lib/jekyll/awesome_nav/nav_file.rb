# frozen_string_literal: true

module Jekyll
  module AwesomeNav
    class NavFile
      attr_reader :items, :options

      def initialize(items:, options:)
        @items = items
        @options = options
      end
    end
  end
end
