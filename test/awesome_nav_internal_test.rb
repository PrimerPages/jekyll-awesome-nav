# frozen_string_literal: true

require "stringio"
require_relative "test_helper"

class AwesomeNavInternalTest < Minitest::Test
  def test_config_applies_defaults_and_normalizes_root
    config = Jekyll::AwesomeNav::Config.new("root" => "/docs/", "nav_filename" => "_menu.yml")

    assert config.enabled?
    assert_equal "docs", config.root_dir
    assert_equal "_menu.yml", config.nav_filename
  end

  def test_config_rejects_non_hash_values
    error = assert_raises(Jekyll::AwesomeNav::Error) do
      Jekyll::AwesomeNav::Config.new(true)
    end

    assert_equal "awesome_nav config must be a mapping", error.message
  end

  def test_unstamped_source_version_warns_with_release_guidance
    output = StringIO.new
    Jekyll::AwesomeNav.instance_variable_set(:@unstamped_version_warning_emitted, false)

    Jekyll::AwesomeNav.send(:warn_if_unstamped_version, output)

    assert_includes output.string, "unstamped source version 0.0.0"
    assert_includes output.string, "Release builds should stamp"
  ensure
    Jekyll::AwesomeNav.instance_variable_set(:@unstamped_version_warning_emitted, true)
  end

  def test_tree_builder_builds_expected_node_structure
    site = process_site
    config = Jekyll::AwesomeNav::Config.new(site.config["awesome_nav"])
    pages = Jekyll::AwesomeNav::PageSet.new(site, config)
    tree = Jekyll::AwesomeNav::TreeBuilder.new(pages: pages, root_dir: config.root_dir).build

    assert_equal ["Guides", "Getting Started"], tree.map(&:title)
    assert tree.first.section?
    assert_equal "/docs/guides/", tree.first.url
    assert_equal "docs/guides/index.md", tree.first.path
    assert_equal "index.md", tree.first.filename
    assert_equal %w[Advanced Configuration Install], tree.first.children.map(&:title)
    assert_equal "docs/guides/advanced/tips.md", tree.first.children.first.children.first.path
    assert_equal "tips.md", tree.first.children.first.children.first.filename
  end

  def test_nav_file_loader_parses_nodes_and_preserves_external_urls
    site = make_site("external_override")
    config = Jekyll::AwesomeNav::Config.new(site.config["awesome_nav"])
    nav_map = Jekyll::AwesomeNav::NavFileLoader.new(site: site, config: config).load
    items = nav_map["docs/guides"].items

    assert_equal ["docs/guides"], nav_map.keys
    assert_equal ["Install Guide", "External Docs"], items.map(&:title)
    assert items.first.reference?
    assert_equal "install.md", items.first.target
    assert_equal "https://example.com/docs", items.last.url
    assert_nil items.last.dir
  end

  def test_nav_file_loader_parses_file_options
    site = make_site("nav_features")
    config = Jekyll::AwesomeNav::Config.new(site.config["awesome_nav"])
    nav_file = Jekyll::AwesomeNav::NavFileLoader.new(site: site, config: config).load["docs"]

    refute_nil nav_file.options
    assert nav_file.options.append_unmatched_or(false)
    assert_equal ["*.hidden.md", "drafts/"], nav_file.options.ignore_patterns_or([])
    assert_equal ["Page Ten", "Page Two"], nav_file.options.sort_options_or(Jekyll::AwesomeNav::SortOptions.from(nil)).sort(
      [
        Jekyll::AwesomeNav::Node.page(dir: "docs/page-10", title: "Page Ten", url: "/docs/page-10/", path: "docs/page-10.md", filename: "page-10.md"),
        Jekyll::AwesomeNav::Node.page(dir: "docs/page-2", title: "Page Two", url: "/docs/page-2/", path: "docs/page-2.md", filename: "page-2.md")
      ]
    ).map(&:title)
  end

  def test_nav_resolver_replaces_nested_subtree
    site = process_site
    config = Jekyll::AwesomeNav::Config.new(site.config["awesome_nav"])
    pages = Jekyll::AwesomeNav::PageSet.new(site, config)
    generated = Jekyll::AwesomeNav::TreeBuilder.new(pages: pages, root_dir: config.root_dir).build
    nav_map = Jekyll::AwesomeNav::NavFileLoader.new(site: site, config: config).load
    resolved = Jekyll::AwesomeNav::NavResolver.new(root_dir: config.root_dir, nav_map: nav_map).apply(generated)

    assert_equal ["Guides", "Getting Started"], resolved.map(&:title)
    assert_equal ["Install Guide", "Configuration"], resolved.first.children.map(&:title)
  end

  def test_nav_resolver_expands_directory_only_globs
    site = process_site
    config = Jekyll::AwesomeNav::Config.new(site.config["awesome_nav"])
    pages = Jekyll::AwesomeNav::PageSet.new(site, config)
    generated = Jekyll::AwesomeNav::TreeBuilder.new(pages: pages, root_dir: config.root_dir).build
    nav_map = Jekyll::AwesomeNav::NavFileLoader.new(site: site, config: config).load
    nav_map["docs"] = nav_file([Jekyll::AwesomeNav::Node.reference(dir: "docs", target: "*/")])

    resolved = Jekyll::AwesomeNav::NavResolver.new(root_dir: config.root_dir, nav_map: nav_map).apply(generated)

    assert_equal ["Guides"], resolved.map(&:title)
    assert_equal ["Install Guide", "Configuration"], resolved.first.children.map(&:title)
  end

  def test_nav_resolver_expands_deep_page_globs_as_a_flat_list
    site = process_site
    config = Jekyll::AwesomeNav::Config.new(site.config["awesome_nav"])
    pages = Jekyll::AwesomeNav::PageSet.new(site, config)
    generated = Jekyll::AwesomeNav::TreeBuilder.new(pages: pages, root_dir: config.root_dir).build
    nav_map = { "docs" => nav_file([Jekyll::AwesomeNav::Node.reference(dir: "docs", target: "**/*.md")]) }

    resolved = Jekyll::AwesomeNav::NavResolver.new(root_dir: config.root_dir, nav_map: nav_map).apply(generated)

    assert_equal ["Getting Started", "Tips", "Configuration", "Install"], resolved.map(&:title)
  end

  def test_nav_resolver_preserves_single_manual_section_at_current_directory
    site = process_site
    config = Jekyll::AwesomeNav::Config.new(site.config["awesome_nav"])
    pages = Jekyll::AwesomeNav::PageSet.new(site, config)
    generated = Jekyll::AwesomeNav::TreeBuilder.new(pages: pages, root_dir: config.root_dir).build
    nav_map = {
      "docs" => nav_file(
        [
          Jekyll::AwesomeNav::Node.section(
            dir: nil,
            title: "Main",
            children: [
              Jekyll::AwesomeNav::Node.reference(dir: "docs", target: "getting-started.md")
            ]
          )
        ]
      )
    }

    resolved = Jekyll::AwesomeNav::NavResolver.new(root_dir: config.root_dir, nav_map: nav_map).apply(generated)

    assert_equal ["Main"], resolved.map(&:title)
    assert_nil resolved.first.url
    assert_equal ["Getting Started"], resolved.first.children.map(&:title)
  end

  def test_serializer_matches_public_hash_shape
    nodes = [
      Jekyll::AwesomeNav::Node.section(
        dir: "docs/guides",
        title: "Guides",
        url: "/docs/guides/",
        children: [
          Jekyll::AwesomeNav::Node.page(dir: "docs/guides/install", title: "Install", url: "/docs/guides/install/")
        ]
      )
    ]

    assert_equal(
      [
        {
          "title" => "Guides",
          "url" => "/docs/guides/",
          "children" => [
            { "title" => "Install", "url" => "/docs/guides/install/" }
          ]
        }
      ],
      Jekyll::AwesomeNav::Serializer.serialize_tree(nodes)
    )
  end

  private

  def nav_file(items)
    Jekyll::AwesomeNav::NavFile.new(items: items, options: Jekyll::AwesomeNav::NavFileOptions.new)
  end
end
