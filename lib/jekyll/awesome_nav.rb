# frozen_string_literal: true

require "jekyll"

require_relative "awesome_nav/version"
require_relative "awesome_nav/generator"

module Jekyll
  module AwesomeNav
    class Error < StandardError; end
  end
end
