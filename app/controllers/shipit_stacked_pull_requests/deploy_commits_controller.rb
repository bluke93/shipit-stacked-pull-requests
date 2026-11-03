# frozen_string_literal: true

module ShipitStackedPullRequests
  # The commits a deploy shipped, or a rollback reverted, loaded when its row is expanded on the stack page.
  class DeployCommitsController < Shipit::ShipitController
    def show
      stack = Shipit::Stack.from_param!(params[:stack_id])
      deploy = stack.deploys.find(params[:id])
      commits = deploy.commits.reorder(id: :desc).preload(:author, :statuses, :check_runs)
      render(partial: 'shipit/deploys/summary', locals: { commits: })
    end
  end
end
