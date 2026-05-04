# frozen_string_literal: true

require "json"
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
    assert_equal(["Guides", "Getting Started"], nav.map { |item| item["title"] })
    assert_equal "/docs/guides/", nav.first["url"]
    assert_equal(["Install Guide", "Configuration"], nav.first["children"].map { |item| item["title"] })
    assert_equal "/docs/guides/config/", nav.first["children"][1]["url"]
    assert_equal({ "title" => "Guides", "url" => "/docs/guides/" }, install_page.data["awesome_nav_previous"])
    assert_equal({ "title" => "Configuration", "url" => "/docs/guides/config/" }, install_page.data["awesome_nav_next"])
  end

  def test_assigns_local_nav_and_breadcrumbs_from_nav_file_subtree
    site = process_site
    install_page = find_page(site, "docs/guides/install.md")

    assert_equal "docs/guides", install_page.data["awesome_nav_dir"]
    assert_equal(["Install Guide", "Configuration"], install_page.data["awesome_nav_local"].map { |item| item["title"] })
    assert_equal(["Documentation", "Guides", "Install Guide"], install_page.data["breadcrumbs"].map { |item| item["title"] })
  end

  def test_descendants_inherit_nav_file_source_directory
    site = process_site
    nested_page = find_page(site, "docs/guides/advanced/tips.md")

    refute_nil nested_page
    assert_equal "docs/guides", nested_page.data["awesome_nav_dir"]
    assert_equal(["Install Guide", "Configuration"], nested_page.data["awesome_nav_local"].map { |item| item["title"] })
    assert_equal [], nested_page.data["breadcrumbs"]
  end

  def test_root_index_page_gets_a_root_breadcrumb
    site = process_site
    root_page = find_page(site, "docs/index.md")

    refute_nil root_page
    assert_equal [{ "title" => "Documentation", "url" => "/docs/" }], root_page.data["breadcrumbs"]
    assert_nil root_page.data["awesome_nav_previous"]
    assert_equal({ "title" => "Guides", "url" => "/docs/guides/" }, root_page.data["awesome_nav_next"])
  end

  def test_ignores_pages_outside_the_configured_root
    site = process_site
    outside_page = find_page(site, "blog/index.md")

    refute_nil outside_page
    refute outside_page.data.key?("awesome_nav")
    refute outside_page.data.key?("awesome_nav_local")
  end

  def test_invalid_nav_file_logs_warning_and_falls_back_to_generated_tree
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

  def test_preserves_external_urls_in_nav_files
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

  def test_directory_insertion_globs_and_append_unmatched
    site = process_site("nav_features")
    page = find_page(site, "docs/getting-started.md")
    nav = page.data["awesome_nav"]
    titles = nav.map { |item| item["title"] }
    guide_titles = nav[2]["children"].map { |item| item["title"] }
    api_titles = nav[7]["children"].map { |item| item["title"] }
    expected_titles = ["Getting Started", "Explicit Hidden", "User Guides", "Reference", "Page Ten", "Page Two", "Changelog", "API"]

    assert_equal expected_titles, titles
    assert_equal "/docs/guides/", nav[2]["url"]
    assert_equal ["Install"], guide_titles
    assert_equal %w[Auth Users], api_titles
  end

  def test_sort_options_apply_to_generated_batches_without_reordering_manual_entries
    site = process_site("nav_features")
    page = find_page(site, "docs/getting-started.md")
    titles = page.data["awesome_nav"].map { |item| item["title"] }

    assert_equal ["Getting Started", "Explicit Hidden", "User Guides"], titles.first(3)
    assert_equal ["Reference", "Page Ten", "Page Two", "Changelog"], titles[3, 4]
    assert_equal "API", titles.last
  end

  def test_ignore_filters_generated_batches_but_not_manual_entries
    site = process_site("nav_features")
    page = find_page(site, "docs/getting-started.md")
    titles = page.data["awesome_nav"].map { |item| item["title"] }

    assert_includes titles, "Explicit Hidden"
    refute_includes titles, "Secret Hidden"
    refute_includes titles, "Drafts"
  end

  def test_hide_stops_hidden_subtrees_even_when_manually_referenced
    site = process_site("nav_features")
    page = find_page(site, "docs/getting-started.md")
    titles = page.data["awesome_nav"].map { |item| item["title"] }

    refute_includes titles, "Archive"
    refute_includes titles, "Manual Hidden"
  end

  def test_append_unmatched_appends_generated_entries_after_manual_nav
    site = process_site("nav_features")
    page = find_page(site, "docs/getting-started.md")
    nav = page.data["awesome_nav"]
    appended_titles = nav.last["children"].map { |item| item["title"] }

    assert_equal "API", nav.last["title"]
    assert_equal "/docs/api/", nav.last["url"]
    assert_equal %w[Auth Users], appended_titles
  end

  def test_append_unmatched_false_hides_omitted_generated_entries
    site = process_site("nav_features")
    page = find_page(site, "docs/guides/install.md")
    local_titles = page.data["awesome_nav_local"].map { |item| item["title"] }

    assert_equal ["Install"], local_titles
    refute_includes local_titles, "Configuration"
    refute_includes local_titles, "Advanced"
  end

  def test_nav_feature_layout_renders_tree_breadcrumbs_and_neighbors
    site = process_site("nav_features")
    page = read_output(site, "docs/guides/install/index.html")

    nav = json_script(page, "awesome-nav")
    local_nav = json_script(page, "awesome-nav-local")
    breadcrumbs = json_script(page, "breadcrumbs")
    previous_item = json_script(page, "previous")
    next_item = json_script(page, "next")
    nav_titles = nav.map { |item| item["title"] }
    local_titles = local_nav.map { |item| item["title"] }
    breadcrumb_titles = breadcrumbs.map { |item| item["title"] }
    expected_nav_titles = [
      "Getting Started", "Explicit Hidden", "User Guides", "Reference", "Page Ten", "Page Two", "Changelog", "API"
    ]

    assert_equal expected_nav_titles, nav_titles
    assert_equal ["Install"], local_titles
    assert_equal ["Documentation", "User Guides", "Install"], breadcrumb_titles
    assert_equal({ "title" => "User Guides", "url" => "/docs/guides/" }, previous_item)
    assert_equal({ "title" => "Reference", "url" => "/docs/reference/" }, next_item)
  end

  def test_nav_feature_layout_renders_root_page_neighbors
    site = process_site("nav_features")
    page = read_output(site, "docs/getting-started/index.html")

    breadcrumbs = json_script(page, "breadcrumbs")
    previous_item = json_script(page, "previous")
    next_item = json_script(page, "next")
    breadcrumb_titles = breadcrumbs.map { |item| item["title"] }

    assert_equal ["Documentation", "Getting Started"], breadcrumb_titles
    assert_equal({ "title" => "Documentation", "url" => "/docs/" }, previous_item)
    assert_equal({ "title" => "Explicit Hidden", "url" => "/docs/explicit.hidden/" }, next_item)
  end

  private

  def read_output(site, relative_path)
    File.read(File.join(site.dest, relative_path))
  end

  def json_script(html, id)
    match = html.match(%r{<div id="#{Regexp.escape(id)}">(.*?)</div>}m)
    refute_nil match, "Expected rendered JSON fixture ##{id}"

    JSON.parse(match[1])
  end
end
