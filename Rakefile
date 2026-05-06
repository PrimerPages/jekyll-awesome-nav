# frozen_string_literal: true

require "bundler/gem_tasks"
require "fileutils"
require "rake/testtask"
require "rubocop/rake_task"

Rake::TestTask.new(:test) do |test|
  test.libs << "test"
  test.pattern = "test/**/*_test.rb"
end

RuboCop::RakeTask.new(:lint)

desc "Build documentation site"
task :site do
  sh "bundle exec jekyll build --source site --destination _site"
end

desc "Serve documentation site"
task :serve do
  sh "bundle exec jekyll serve --source site --destination _site --livereload"
end

desc "Remove local build and cache artifacts"
task :clean do
  artifacts = [
    "_site",
    ".jekyll-cache",
    ".sass-cache"
  ]
  artifacts.each { |path| FileUtils.rm_rf(path) }
end

task default: :test
