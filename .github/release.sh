#!/usr/bin/env bash
set -euo pipefail

load_env_file() {
  local env_file=".env"
  if [[ -f "$env_file" ]]; then
    echo "Loading environment variables from $env_file..."
    set -a
    # shellcheck disable=SC1090
    source "$env_file"
    set +a
  fi
}

build_gem() {
  local gemspec_file="$1"

  if [[ ! -f "$gemspec_file" ]]; then
    echo "Error: Gemspec file '$gemspec_file' not found."
    exit 1
  fi

  gem build "$gemspec_file" | awk '/File:/ {print $2}'
}

setup_rubygems_credentials() {
  if [[ -z "${RUBYGEMS_USERNAME:-}" || -z "${RUBYGEMS_API_KEY:-}" ]]; then
    echo "Error: RUBYGEMS_USERNAME and RUBYGEMS_API_KEY environment variables must be set."
    exit 1
  fi

  mkdir -p ~/.gem
  echo -e "---\n:rubygems_api_key: $RUBYGEMS_API_KEY" > ~/.gem/credentials
  chmod 0600 ~/.gem/credentials
}

upload_gem() {
  local gem_file="$1"

  if [[ ! -f "$gem_file" ]]; then
    echo "Error: Gem file '$gem_file' not found."
    exit 1
  fi

  gem push "$gem_file" --host https://rubygems.org
}

if [[ "$#" -ne 1 ]]; then
  echo "Usage: $0 <path_to_gemspec_file>"
  exit 1
fi

load_env_file
generated_gem_file="$(build_gem "$1")"
echo "Generated gem file: $generated_gem_file"

setup_rubygems_credentials
upload_gem "$generated_gem_file"
echo "Pushed gem file: $generated_gem_file"
