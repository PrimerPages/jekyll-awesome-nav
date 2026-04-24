# frozen_string_literal: true

module Jekyll
  module AwesomeNav
    class Config
      DEFAULTS = {
        "enabled" => true,
        "root" => "docs",
        "nav_filename" => "_nav.yml"
      }.freeze

      def initialize(raw_config)
        raise Error, "awesome_nav config must be a mapping" unless raw_config.nil? || raw_config.is_a?(Hash)

        @data = DEFAULTS.merge(raw_config || {})
      end

      def enabled?
        @data["enabled"]
      end

      def root_dir
        Utils.normalize_dir(@data["root"])
      end

      def nav_filename
        @data["nav_filename"].to_s
      end
    end
  end
end
