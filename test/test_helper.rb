# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'
ENV['REDIS_URL'] ||= 'redis://127.0.0.1:6379/7'

require 'webmock/minitest'
require_relative 'dummy/config/environment'
require 'rails/test_help'
require 'mocha/minitest'

module ActiveSupport
  class TestCase
    include ActiveJob::TestHelper

    # Shipit's own fixtures (stacks, commits, deploys...), which come with its source.
    self.fixture_paths = [Shipit::Engine.root.join('test/fixtures').to_s]
    fixtures :all

    setup do
      Shipit.github.api.stubs(:login).returns('shipit')
    end

    teardown do
      ShipitStackedPullRequests.enabled_by_default = false
      Shipit.redis.flushdb
      Shipit.instance_variable_names.each do |name|
        Shipit.remove_instance_variable(name) unless %w[@mocha @redis].include?(name)
      end
    end

    private

    def group_stacked_pull_requests(stack)
      config = stack.cached_deploy_spec.config.deep_merge('deploy' => { 'group_stacked_pull_requests' => true })
      stack.update!(cached_deploy_spec: Shipit::DeploySpec.new(config))
    end

    def stack_pull_requests(commits, stack_number: 580)
      commits.each { |commit| ShipitStackedPullRequests::CommitStack.create!(commit:, stack_number:) }
    end
  end
end
