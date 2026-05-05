# frozen_string_literal: true

module Jekyll
  module AwesomeNav
    VERSION = "0.0.0"

    def self.warn_if_unstamped_version(output = $stderr)
      return unless VERSION == "0.0.0"
      return if @unstamped_version_warning_emitted

      output.puts(
        "Warning: jekyll-awesome-nav is using unstamped source version 0.0.0. " \
        "Release builds should stamp lib/jekyll/awesome_nav/version.rb before packaging."
      )
      @unstamped_version_warning_emitted = true
    end
    private_class_method :warn_if_unstamped_version
  end
end
