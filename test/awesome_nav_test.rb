# frozen_string_literal: true

require "json"
require_relative "test_helper"

module AwesomeNavTestHelpers
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

class AwesomeNavCoreTest < Minitest::Test
  include AwesomeNavTestHelpers

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
    current_branch = nav.first
    sibling_branch = nav[1]
    current_leaf = current_branch["children"][0]
    sibling_leaf = current_branch["children"][1]
    nav_titles = nav.map { |item| item["title"] }
    child_titles = current_branch["children"].map { |item| item["title"] }

    assert_equal ["Guides", "Getting Started"], nav_titles
    assert_equal "/docs/guides/", current_branch["url"]
    assert_equal false, current_branch["current"]
    assert_equal true, current_branch["contains_current"]
    assert_equal false, sibling_branch["current"]
    assert_equal false, sibling_branch["contains_current"]
    assert_equal ["Install Guide", "Configuration"], child_titles
    assert_equal "/docs/guides/config/", sibling_leaf["url"]
    assert_equal true, current_leaf["current"]
    assert_equal true, current_leaf["contains_current"]
    assert_equal false, sibling_leaf["current"]
    assert_equal false, sibling_leaf["contains_current"]
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

  def test_assigns_nav_to_readme_index_pages
    site = process_site("readme_index")
    root_page = find_page(site, "README.md")
    nested_page = find_page(site, "gazebo/README.md")

    refute_nil root_page
    refute_nil nested_page
    assert root_page.data.key?("awesome_nav")
    assert nested_page.data.key?("awesome_nav")
    assert_equal "/", root_page.url
    assert_equal "/gazebo/", nested_page.url
  end

  def test_ignores_assets_pages_when_assigning_nav
    site = process_site("readme_index")
    assets_page = find_page(site, "assets/css/style.scss")

    return assert_nil(assets_page) if assets_page.nil?

    refute assets_page.data.key?("awesome_nav")
    refute assets_page.data.key?("awesome_nav_local")
    refute assets_page.data.key?("awesome_nav_dir")
    refute assets_page.data.key?("breadcrumbs")
  end

  def test_empty_root_does_not_prepend_blank_breadcrumb_title
    site = process_site("readme_index")
    page = find_page(site, "README.md")

    refute_nil page
    refute_nil page.data["breadcrumbs"]
    refute_includes page.data["breadcrumbs"].map { |item| item["title"] }, ""
  end

  def test_empty_root_nested_pages_include_home_breadcrumb
    site = process_site("readme_index")
    page = find_page(site, "ros2/README.md")

    refute_nil page
    assert_equal(%w[home Ros2], page.data["breadcrumbs"].map { |item| item["title"] })
  end

  def test_readme_index_pages_render_as_section_links_not_nested_readme_children
    site = process_site("readme_index")
    page = find_page(site, "ros2/README.md")
    ros2_item = page.data["awesome_nav"].find { |item| item["title"] == "Ros2" }

    refute_nil page
    refute_nil ros2_item
    assert_equal "/ros2/", ros2_item["url"]
    refute_includes Array(ros2_item["children"]).map { |item| item["title"] }, "README"
  end

  def test_empty_root_uses_root_page_title_for_prev_next
    site = process_site("readme_index")
    page = find_page(site, "docker-compose/README.md")

    refute_nil page
    assert_equal({ "title" => "home", "url" => "/" }, page.data["awesome_nav_previous"])
  end

  def test_untitled_index_pages_use_their_folder_name_for_titles
    site = process_site("untitled_index")
    install_page = find_page(site, "docs/guides/install.md")

    refute_nil install_page
    assert_equal(["Guides"], install_page.data["awesome_nav"].map { |item| item["title"] })
    assert_equal(%w[Docs Guides Install], install_page.data["breadcrumbs"].map { |item| item["title"] })
  end

  def test_breadcrumbs_only_expose_title_and_url
    site = process_site
    install_page = find_page(site, "docs/guides/install.md")

    refute_nil install_page
    assert_equal(
      [
        { "title" => "Documentation", "url" => "/docs/" },
        { "title" => "Guides", "url" => "/docs/guides/" },
        { "title" => "Install Guide", "url" => "/docs/guides/install/" }
      ],
      install_page.data["breadcrumbs"]
    )
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
    refute_includes titles, "Deep Archive"
    refute_includes titles, "Nested Archive Override"
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
end

class AwesomeNavRenderingTest < Minitest::Test
  include AwesomeNavTestHelpers

  def test_readme_index_and_optional_front_matter_preserve_manual_root_section
    site = process_site("readme_manual_section")
    page = find_page(site, "README.md")
    nav = page.data["awesome_nav"]
    api_section = nav.find { |item| item["title"] == "API Reference" }
    api_titles = api_section["children"].map { |item| item["title"] }
    expected_root_item = {
      "title" => "README",
      "url" => "/",
      "current" => true,
      "contains_current" => true
    }

    refute_nil page
    assert_equal expected_root_item, nav.first
    refute_nil api_section
    assert_nil api_section["url"]
    assert_equal %w[Cli Config Extractor Materialize Scanner], api_titles
  end

  def test_append_unmatched_false_hides_omitted_generated_entries
    site = process_site("nav_features")
    page = find_page(site, "docs/guides/install.md")
    local_titles = page.data["awesome_nav_local"].map { |item| item["title"] }

    assert_equal ["Install"], local_titles
    refute_includes local_titles, "Configuration"
    refute_includes local_titles, "Advanced"
  end

  def test_manual_entries_do_not_duplicate_generated_sources
    site = process_site("manual_dedup")
    page = find_page(site, "site/index.md")
    nav = page.data["awesome_nav"]
    nav_titles = nav.map { |item| item["title"] }
    guides_children = nav[2]["children"]
    guides_titles = guides_children.map { |item| item["title"] }

    assert_equal ["Overview", "Getting Started", "Guides", "Extracted Reference"], nav_titles
    assert_equal "/site/", nav[0]["url"]
    assert_equal "/site/getting-started/", nav[1]["url"]
    assert_equal ["Overview", "Writing Guides", "Deeper Navigation"], guides_titles
    assert_equal "/site/guides/", guides_children[0]["url"]
    assert_nil guides_children[0]["children"]
    assert_equal "/site/guides/configuration/", guides_children[1]["url"]
    assert_equal "/site/guides/advanced/overrides/", guides_children[2]["url"]
    assert_equal "/site/src/extracted/", nav[3]["url"]
    refute_includes nav.map { |item| item["title"] }, "Src"
  end

  def test_root_index_reference_resolves_to_a_single_root_link
    site = process_site("manual_dedup")
    page = find_page(site, "site/index.md")
    nav = page.data["awesome_nav"]
    overview_items = nav.select { |item| item["title"] == "Overview" }
    expected_overview_item = {
      "title" => "Overview",
      "url" => "/site/",
      "current" => true,
      "contains_current" => true
    }

    assert_equal 1, overview_items.length
    assert_equal expected_overview_item, overview_items.first
  end

  def test_explicit_item_is_not_duplicated_by_glob_match
    site = process_site("nav_features")
    page = find_page(site, "docs/getting-started.md")
    nav = page.data["awesome_nav"]
    getting_started_items = nav.select { |item| item["title"] == "Getting Started" }
    expected_item = {
      "title" => "Getting Started",
      "url" => "/docs/getting-started/",
      "current" => true,
      "contains_current" => true
    }

    assert_equal 1, getting_started_items.length
    assert_equal expected_item, getting_started_items.first
  end

  def test_nested_nav_index_reference_resolves_without_duplicate_generated_items
    site = process_site("nested_manual_dedup")
    page = find_page(site, "site/guides/index.md")
    nav = page.data["awesome_nav"]
    nav_titles = nav.map { |item| item["title"] }

    assert_equal ["Overview", "Writing Guides", "Deeper Navigation"], nav_titles
    assert_equal "/site/guides/", nav[0]["url"]
    assert_nil nav[0]["children"]
    refute_includes nav_titles, "Advanced"
    refute_includes nav_titles, "Guides Home"
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
end
