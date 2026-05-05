# frozen_string_literal: true

require "jekyll"

require_relative "awesome_nav/utils"
require_relative "awesome_nav/config"
require_relative "awesome_nav/node"
require_relative "awesome_nav/sort_options"
require_relative "awesome_nav/nav_file_options"
require_relative "awesome_nav/nav_file"
require_relative "awesome_nav/page_set"
require_relative "awesome_nav/tree_builder"
require_relative "awesome_nav/nav_file_loader"
require_relative "awesome_nav/nav_resolver"
require_relative "awesome_nav/serializer"
require_relative "awesome_nav/navigation_result"
require_relative "awesome_nav/version"
require_relative "awesome_nav/generator"

module Jekyll
  module AwesomeNav
    class Error < StandardError; end
  end
end

Jekyll::AwesomeNav.send(:warn_if_unstamped_version)
