# frozen_string_literal: true

require "bundler/setup"
require "fileutils"
require "minitest/autorun"
require "tmpdir"
require "jekyll"
require "jekyll-awesome-nav"

module AwesomeNavTestHelpers
  def fixture_path(*parts)
    File.expand_path(File.join("fixtures", *parts), __dir__)
  end

  def make_site(fixture = "site", overrides = {})
    source = fixture_path(fixture)
    tmp_root = File.join(Dir.tmpdir, "jekyll-awesome-nav-tests")
    destination = File.join(tmp_root, fixture, "site")
    cache_dir = File.join(tmp_root, fixture, ".jekyll-cache")

    FileUtils.rm_rf(destination)
    FileUtils.rm_rf(cache_dir)

    config = Jekyll.configuration(
      {
        "source" => source,
        "destination" => destination,
        "cache_dir" => cache_dir,
        "disable_disk_cache" => true,
        "quiet" => true
      }.merge(overrides)
    )

    Jekyll::Site.new(config)
  end

  def process_site(fixture = "site", overrides = {})
    site = make_site(fixture, overrides)
    site.process
    site
  end

  def find_page(site, relative_path)
    expected = relative_path.sub(%r{\A/+}, "")
    site.pages.find do |page|
      [
        page.path,
        page.relative_path,
        page.instance_variable_get(:@relative_path)
      ].compact.any? { |value| value.to_s.sub(%r{\A/+}, "") == expected }
    end
  end
end

class Minitest::Test
  include AwesomeNavTestHelpers
end
