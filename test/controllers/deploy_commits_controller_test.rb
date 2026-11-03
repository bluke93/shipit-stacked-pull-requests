# frozen_string_literal: true

require 'test_helper'

module ShipitStackedPullRequests
  class DeployCommitsControllerTest < ActionController::TestCase
    setup do
      @routes = Engine.routes
      @stack = shipit_stacks(:shipit)
      @deploy = shipit_tasks(:shipit)
      session[:user_id] = shipit_users(:walrus).id
    end

    test "#show renders the commits shipped by the deploy" do
      get :show, params: { stack_id: @stack.to_param, id: @deploy.id }

      assert_response :success
      assert_select '.commit-summary', count: @deploy.commits.size
      assert_select '.commit-summary__title', text: @deploy.until_commit.title
    end

    test "#show lists the commits a rollback reverts, newest first" do
      rollback = @stack.rollbacks.create!(
        deploy: @deploy,
        since_commit: shipit_commits(:fourth),
        until_commit: shipit_commits(:second),
        user: shipit_users(:walrus),
        status: 'success'
      )

      get :show, params: { stack_id: @stack.to_param, id: rollback.id }

      assert_response :success
      titles = css_select('.commit-summary__title').map { |title| title.text.strip }
      assert_equal [shipit_commits(:fourth).title, shipit_commits(:third).title], titles
    end

    test "#show only finds deploys of the given stack" do
      other_stack = shipit_stacks(:cyclimse)

      assert_raises(ActiveRecord::RecordNotFound) do
        get :show, params: { stack_id: other_stack.to_param, id: @deploy.id }
      end
    end
  end
end
