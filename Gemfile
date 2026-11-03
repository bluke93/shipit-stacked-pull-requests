# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

# The test suite uses Shipit's fixtures, which come with its source rather than its gem.
# Point SHIPIT_ENGINE_PATH at a local checkout to run against it instead of the pinned release.
if ENV['SHIPIT_ENGINE_PATH']
  gem 'shipit-engine', path: ENV['SHIPIT_ENGINE_PATH']
else
  gem 'shipit-engine', github: 'Shopify/shipit-engine', ref: '2f629b62e8bd2d86006f45865f1c6bccaf67176a' # 0.45.5
end

gem 'ejson-rails'
gem 'sqlite3', '>= 2.1'

group :development do
  gem 'faker'
  gem 'webrick'
end

group :test do
  gem 'mocha'
  gem 'webmock'
end
