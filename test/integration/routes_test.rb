# frozen_string_literal: true

require 'test_helper'

module ShipitStackedPullRequests
  class RoutesTest < ActionDispatch::IntegrationTest
    setup do
      Shipit.stubs(:authentication_disabled?).returns(true)
      @stack = shipit_stacks(:shipit)
    end

    test "the extension's routes are mounted in the host application" do
      get "/stacked_pull_requests/#{@stack.to_param}/deploys/#{shipit_tasks(:shipit).id}/commits"

      assert_response :success
      assert_select '.commit-summary'
    end

    test "Shipit's own routes still work" do
      get "/#{@stack.to_param}"

      assert_response :success
      assert_select '.commit-list'
    end
  end
end
