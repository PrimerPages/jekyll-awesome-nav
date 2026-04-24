# frozen_string_literal: true

source "https://rubygems.org"

gemspec

gem "jekyll", ENV["JEKYLL_VERSION"] if ENV["JEKYLL_VERSION"]

gem "jekyll-seo-tag"
gem "jekyll-theme-profile"
gem "minitest", "~> 5.0"
gem "rake", "~> 13.0"
gem "rubocop", require: false
gem "webrick", "~> 1.8"

# Required in Ruby 3.4+ when Jekyll < 4.4
gem "base64"
gem "bigdecimal"
gem "csv"
gem "logger"

# Required in Ruby 3.3.4 when Jekyll == 3.10
gem "kramdown-parser-gfm"
