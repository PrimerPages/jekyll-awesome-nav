#!/usr/bin/env bash
set -euo pipefail

bundle exec jekyll build --source site --destination /tmp/jekyll-awesome-nav-site
