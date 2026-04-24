# frozen_string_literal: true

require_relative "lib/jekyll/awesome_nav/version"

Gem::Specification.new do |spec|
  spec.name = "jekyll-awesome-nav"
  spec.version = Jekyll::AwesomeNav::VERSION
  spec.authors = ["Allison Thackston"]
  spec.email = ["allison@allisonthackston.com"]

  spec.summary = "Folder-based navigation for Jekyll with local subtree overrides."
  spec.description = "Build a full navigation tree from a docs directory and let any folder replace its subtree with a local _nav.yml file."
  spec.homepage = "https://github.com/PrimerPages/jekyll-awesome-nav"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["bug_tracker_uri"] = "#{spec.homepage}/issues"
  spec.metadata["documentation_uri"] = "https://primerpages.github.io/jekyll-awesome-nav/"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.add_dependency "jekyll", ">= 3.9", "< 5.0"
end
