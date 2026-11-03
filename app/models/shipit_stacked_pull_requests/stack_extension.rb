# frozen_string_literal: true

module ShipitStackedPullRequests
  module StackExtension
    def group_stacked_pull_requests?
      return ShipitStackedPullRequests.enabled_by_default unless cached_deploy_spec

      cached_deploy_spec.group_stacked_pull_requests?
    end
  end
end
