#!/usr/bin/env bash
set -euo pipefail

VERSION_FILE="lib/jekyll/awesome_nav/version.rb"

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: $0 <version> [--dry-run]"
  exit 1
fi

new_version="$1"
dry_run="${2:-}"

if [[ "$dry_run" != "" && "$dry_run" != "--dry-run" ]]; then
  echo "Unknown option: $dry_run"
  echo "Usage: $0 <version> [--dry-run]"
  exit 1
fi

if ! [[ "$new_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Invalid version format: $new_version"
  echo "Expected format: x.y.z (e.g., 1.2.3)"
  exit 1
fi

if [[ ! -f "$VERSION_FILE" ]]; then
  echo "Version file not found: $VERSION_FILE"
  exit 1
fi

tmp_file="$(mktemp)"
trap 'rm -f "$tmp_file"' EXIT

sed -E 's/VERSION = "[0-9]+\.[0-9]+\.[0-9]+"/VERSION = "'"$new_version"'"/' "$VERSION_FILE" > "$tmp_file"

if cmp -s "$VERSION_FILE" "$tmp_file"; then
  echo "No version update was made in $VERSION_FILE"
  exit 1
fi

if [[ "$dry_run" == "--dry-run" ]]; then
  echo "Dry run: would update $VERSION_FILE to $new_version"
  diff -u "$VERSION_FILE" "$tmp_file" || true
  exit 0
fi

cp "$tmp_file" "$VERSION_FILE"
echo "Updated $VERSION_FILE to version $new_version"
