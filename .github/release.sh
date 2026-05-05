#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 <version> [--publish]"
}

normalize_version() {
  local version="$1"
  version="${version#v}"

  if ! [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+([.-][0-9A-Za-z.-]+)?$ ]]; then
    echo "Invalid version format: $1" >&2
    echo "Expected a RubyGems-compatible version such as 1.2.3 or v1.2.3." >&2
    exit 1
  fi
  if [[ "$version" == "0.0.0" ]]; then
    echo "Refusing to release unstamped source version 0.0.0." >&2
    exit 1
  fi

  printf '%s\n' "$version"
}

update_version_file() {
  local version="$1"
  local version_file="lib/jekyll/awesome_nav/version.rb"

  if [[ ! -f "$version_file" ]]; then
    echo "Version file not found: $version_file" >&2
    exit 1
  fi

  ruby -e '
    version_file, version = ARGV
    content = File.read(version_file)
    unless content.match?(/VERSION = "[^"]+"/)
      warn "VERSION constant not found in #{version_file}"
      exit 1
    end
    updated = content.sub(/VERSION = "[^"]+"/, "VERSION = \"#{version}\"")
    File.write(version_file, updated)
  ' "$version_file" "$version"
  echo "Updated $version_file to version $version"
}

build_gem() {
  local version="$1"
  local gemspec_file="jekyll-awesome-nav.gemspec"
  local gem_file="pkg/jekyll-awesome-nav-${version}.gem"

  mkdir -p pkg
  gem build "$gemspec_file" --output "$gem_file" >/dev/null
  echo "$gem_file"
}

publish_gem() {
  local gem_file="$1"

  gem push "$gem_file"
}

if [[ "$#" -lt 1 || "$#" -gt 2 ]]; then
  usage >&2
  exit 1
fi

raw_version="$1"
publish="${2:-}"

if [[ -n "$publish" && "$publish" != "--publish" ]]; then
  usage >&2
  exit 1
fi

version="$(normalize_version "$raw_version")"
update_version_file "$version"
gem_file="$(build_gem "$version")"
echo "Built $gem_file"

if [[ "$publish" == "--publish" ]]; then
  publish_gem "$gem_file"
fi
