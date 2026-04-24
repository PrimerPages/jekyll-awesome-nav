# frozen_string_literal: true

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

  def test_tree_builder_builds_expected_node_structure
    site = process_site
    config = Jekyll::AwesomeNav::Config.new(site.config["awesome_nav"])
    pages = Jekyll::AwesomeNav::PageSet.new(site, config)
    tree = Jekyll::AwesomeNav::TreeBuilder.new(pages: pages, root_dir: config.root_dir).build

    assert_equal ["Guides", "Getting Started"], tree.map(&:title)
    assert tree.first.section?
    assert_equal "/docs/guides/", tree.first.url
    assert_equal %w[Advanced Configuration Install], tree.first.children.map(&:title)
  end

  def test_override_loader_parses_nodes_and_preserves_external_urls
    site = make_site("external_override")
    config = Jekyll::AwesomeNav::Config.new(site.config["awesome_nav"])
    overrides = Jekyll::AwesomeNav::OverrideLoader.new(site: site, config: config).load

    assert_equal ["docs/guides"], overrides.keys
    assert_equal ["Install Guide", "External Docs"], overrides["docs/guides"].map(&:title)
    assert_equal "https://example.com/docs", overrides["docs/guides"].last.url
    assert_nil overrides["docs/guides"].last.dir
  end

  def test_override_resolver_replaces_nested_subtree
    site = process_site
    config = Jekyll::AwesomeNav::Config.new(site.config["awesome_nav"])
    pages = Jekyll::AwesomeNav::PageSet.new(site, config)
    generated = Jekyll::AwesomeNav::TreeBuilder.new(pages: pages, root_dir: config.root_dir).build
    overrides = Jekyll::AwesomeNav::OverrideLoader.new(site: site, config: config).load
    resolved = Jekyll::AwesomeNav::OverrideResolver.new(root_dir: config.root_dir, override_map: overrides).apply(generated)

    assert_equal ["Guides Hub", "Getting Started"], resolved.map(&:title)
    assert_equal ["Install Guide", "Configuration"], resolved.first.children.map(&:title)
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
end
