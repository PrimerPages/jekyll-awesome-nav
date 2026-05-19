# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "jekyll-awesome-nav-preview-theme"
  spec.version       = "0.1.0"
  spec.authors       = ["OpenAI"]
  spec.email         = ["support@openai.com"]
  spec.summary       = "Local preview theme for jekyll-awesome-nav fixtures"
  spec.description   = "A tiny local Jekyll theme used to preview fixture navigation, breadcrumbs, and debug data."
  spec.homepage      = "https://example.invalid/jekyll-awesome-nav-preview-theme"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 2.7.0"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(__dir__) do
    Dir[
      "_layouts/**/*",
      "_includes/**/*",
      "_sass/**/*",
      "assets/**/*",
      "lib/**/*",
      "*.gemspec"
    ]
  end
  spec.require_paths = ["lib"]

  spec.add_dependency "jekyll", ">= 3.10", "< 5.0"
end
