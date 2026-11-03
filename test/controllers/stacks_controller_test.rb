# frozen_string_literal: true

require 'test_helper'

module ShipitStackedPullRequests
  class StacksControllerTest < ActionController::TestCase
    tests Shipit::StacksController

    setup do
      @routes = Shipit::Engine.routes
      @stack = shipit_stacks(:shipit)
      session[:user_id] = shipit_users(:walrus).id
    end

    test "#show nests the earlier pull requests of a stack under the newest one" do
      group_stacked_pull_requests(@stack)
      newest, earlier = @stack.undeployed_commits.reject(&:active?).first(2)
      stack_pull_requests([newest, earlier])

      get :show, params: { id: @stack.to_param }

      assert_response :ok
      assert_select "#commit-#{newest.id} .pull-request-stack-toggle[aria-expanded=true]", text: /Stack of 2/
      assert_select "#commit-#{newest.id} > #pull-request-stack-#{newest.id}:not([hidden]) > #commit-#{earlier.id}"
      assert_select "section > .commit-list > #commit-#{earlier.id}", count: 0
    end

    test "#show doesn't group stacked pull requests unless the stack opts in" do
      newest, earlier = @stack.undeployed_commits.reject(&:active?).first(2)
      stack_pull_requests([newest, earlier])

      get :show, params: { id: @stack.to_param }

      assert_response :ok
      assert_select ".pull-request-stack-toggle", count: 0
      assert_select ".wrapper > section:nth-of-type(1) > .commit-list > #commit-#{earlier.id}"
    end

    test "#show groups the stacks being deployed" do
      group_stacked_pull_requests(@stack)
      newest, earlier = @stack.undeployed_commits.first(2)
      stack_pull_requests([newest, earlier])
      running = shipit_tasks(:shipit_running)
      @stack.tasks.where(status: Shipit::Task::ACTIVE_STATUSES).where.not(id: running.id).update_all(status: 'success')
      running.update!(allow_concurrency: false, since_commit_id: @stack.last_deployed_commit.id, until_commit_id: newest.id)

      get :show, params: { id: @stack.to_param }

      assert_response :ok
      deploying = ".wrapper > section:nth-of-type(2) > .commit-list"
      assert_select "#{deploying} > #commit-#{newest.id} > #pull-request-stack-#{newest.id} > #commit-#{earlier.id}"
      assert_select ".wrapper > section:nth-of-type(1) #commit-#{newest.id}", count: 0
    end

    test "#show groups a stack split by an unrelated pull request" do
      group_stacked_pull_requests(@stack)
      unrelated, oldest = @stack.undeployed_commits.reject(&:active?).first(2)
      newest = @stack.commits.create!(sha: SecureRandom.hex(20), message: 'Newest', authored_at: Time.now,
                                      committed_at: Time.now)
      stack_pull_requests([newest, oldest])

      get :show, params: { id: @stack.to_param }

      assert_response :ok
      assert_select "#pull-request-stack-#{newest.id} > #commit-#{oldest.id}"
      assert_select ".wrapper > section:nth-of-type(1) > .commit-list > #commit-#{unrelated.id}"
    end

    test "#show warns about failing and locked pull requests hidden in a stack" do
      group_stacked_pull_requests(@stack)
      newest, earlier = @stack.undeployed_commits.reject(&:active?).first(2)
      stack_pull_requests([newest, earlier])
      earlier.update!(locked: true)
      earlier.statuses.create!(stack_id: @stack.id, state: 'failure', context: 'ci/travis', description: 'Failed')

      get :show, params: { id: @stack.to_param }

      assert_response :ok
      assert_select "#commit-#{newest.id} .pull-request-stack-warning", text: '1 failing · 1 locked'
    end

    test "#show lets previous deploys expand to the commits they shipped" do
      deploy = shipit_tasks(:shipit)

      get :show, params: { id: @stack.to_param }

      assert_response :ok
      commits_path = "/stacked_pull_requests/#{@stack.to_param}/deploys/#{deploy.id}/commits"
      assert_select "#task-#{deploy.id} .deploy-commits-toggle[data-accordion-src='#{commits_path}']"
      assert_select "#deploy-#{deploy.id}-commits[hidden]"
    end

    test "#show loads the extension's assets" do
      get :show, params: { id: @stack.to_param }

      assert_response :ok
      assert_select "link[rel=stylesheet][href*='shipit_stacked_pull_requests']"
      assert_select "script[src*='shipit_stacked_pull_requests']"
    end
  end
end
