# frozen_string_literal: true

require 'test_helper'

module ShipitStackedPullRequests
  class DeploySpecExtensionTest < ActiveSupport::TestCase
    test "stacked pull requests aren't grouped by default" do
      refute_predicate Shipit::DeploySpec.new({}), :group_stacked_pull_requests?
    end

    test "shipit.yml can group stacked pull requests" do
      spec = Shipit::DeploySpec.new('deploy' => { 'group_stacked_pull_requests' => true })
      assert_predicate spec, :group_stacked_pull_requests?
    end

    test "the default can be changed for every stack, and shipit.yml can still opt out" do
      ShipitStackedPullRequests.enabled_by_default = true

      assert_predicate Shipit::DeploySpec.new({}), :group_stacked_pull_requests?
      refute_predicate Shipit::DeploySpec.new('deploy' => { 'group_stacked_pull_requests' => false }),
                       :group_stacked_pull_requests?
    end
  end
end
