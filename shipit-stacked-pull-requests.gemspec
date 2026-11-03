# frozen_string_literal: true

require_relative 'lib/shipit_stacked_pull_requests/version'

Gem::Specification.new do |s|
  s.name = 'shipit-stacked-pull-requests'
  s.version = ShipitStackedPullRequests::VERSION
  s.authors = ['Luca Barone']
  s.email = ['baroneluca93@gmail.com']
  s.summary = 'Groups GitHub stacked pull requests on Shipit stack pages.'
  s.description = <<~DESCRIPTION
    A Shipit extension that groups the undeployed commits belonging to the same GitHub stacked pull request
    under the newest one, and lets previous deploys expand to the commits they shipped.
  DESCRIPTION
  s.license = 'MIT'

  s.files = Dir['{app,config,db,lib}/**/*', 'LICENSE.txt', 'README.md']
  s.required_ruby_version = '>= 3.2.0'

  s.add_dependency('shipit-engine', '~> 0.45')
end
