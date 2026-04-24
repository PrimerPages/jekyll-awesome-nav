# frozen_string_literal: true

require_relative "test_helper"

class AwesomeNavTest < Minitest::Test
  WarningLogger = Struct.new(:warnings) do
    def warn(topic, message)
      warnings << [topic, message]
    end

    def debug(*); end
    def info(*); end
    def method_missing(*); end

    def respond_to_missing?(*)
      true
    end
  end

  def test_generates_full_tree_with_expected_data_keys
    site = process_site
    install_page = find_page(site, "docs/guides/install.md")

    refute_nil install_page
    assert install_page.data.key?("awesome_nav")
    assert install_page.data.key?("awesome_nav_local")
    assert install_page.data.key?("awesome_nav_dir")
    assert install_page.data.key?("awesome_nav_previous")
    assert install_page.data.key?("awesome_nav_next")

    nav = install_page.data["awesome_nav"]
    assert_equal(["Guides Hub", "Getting Started"], nav.map { |item| item["title"] })
    assert_equal "/docs/guides/", nav.first["url"]
    assert_equal(["Install Guide", "Configuration"], nav.first["children"].map { |item| item["title"] })
    assert_equal "/docs/guides/config/", nav.first["children"][1]["url"]
    assert_equal({ "title" => "Guides Hub", "url" => "/docs/guides/" }, install_page.data["awesome_nav_previous"])
    assert_equal({ "title" => "Configuration", "url" => "/docs/guides/config/" }, install_page.data["awesome_nav_next"])
  end

  def test_assigns_local_nav_and_breadcrumbs_from_override_subtree
    site = process_site
    install_page = find_page(site, "docs/guides/install.md")

    assert_equal "docs/guides", install_page.data["awesome_nav_dir"]
    assert_equal(["Install Guide", "Configuration"], install_page.data["awesome_nav_local"].map { |item| item["title"] })
    assert_equal(["Documentation", "Guides Hub", "Install Guide"], install_page.data["breadcrumbs"].map { |item| item["title"] })
  end

  def test_descendants_inherit_override_source_directory
    site = process_site
    nested_page = find_page(site, "docs/guides/advanced/tips.md")

    refute_nil nested_page
    assert_equal "docs/guides", nested_page.data["awesome_nav_dir"]
    assert_equal [], nested_page.data["awesome_nav_local"]
    assert_equal [], nested_page.data["breadcrumbs"]
  end

  def test_root_index_page_gets_a_root_breadcrumb
    site = process_site
    root_page = find_page(site, "docs/index.md")

    refute_nil root_page
    assert_equal [{ "title" => "Documentation", "url" => "/docs/" }], root_page.data["breadcrumbs"]
    assert_nil root_page.data["awesome_nav_previous"]
    assert_equal({ "title" => "Guides Hub", "url" => "/docs/guides/" }, root_page.data["awesome_nav_next"])
  end

  def test_ignores_pages_outside_the_configured_root
    site = process_site
    outside_page = find_page(site, "blog/index.md")

    refute_nil outside_page
    refute outside_page.data.key?("awesome_nav")
    refute outside_page.data.key?("awesome_nav_local")
  end

  def test_invalid_override_logs_warning_and_falls_back_to_generated_tree
    site = make_site("invalid_override")
    logger = WarningLogger.new([])

    original_logger = Jekyll.logger
    Jekyll.instance_variable_set(:@logger, logger)
    site.process

    install_page = find_page(site, "docs/guides/install.md")
    assert_equal(%w[Documentation Guides Install], install_page.data["breadcrumbs"].map { |item| item["title"] })
    assert(logger.warnings.any? { |topic, message| topic == "AwesomeNav:" && message.include?("Could not load") })
  ensure
    Jekyll.instance_variable_set(:@logger, original_logger)
  end

  def test_preserves_external_urls_in_overrides
    site = process_site("external_override")
    install_page = find_page(site, "docs/guides/install.md")

    refute_nil install_page
    external_item = install_page.data["awesome_nav"].find { |item| item["title"] == "External Docs" }

    assert_equal "https://example.com/docs", external_item["url"]
  end

  def test_can_be_disabled
    site = process_site("site", "awesome_nav" => { "enabled" => false, "root" => "docs" })
    install_page = find_page(site, "docs/guides/install.md")

    refute install_page.data.key?("awesome_nav")
  end
end
