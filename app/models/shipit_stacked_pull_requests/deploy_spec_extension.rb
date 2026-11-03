# frozen_string_literal: true

module ShipitStackedPullRequests
  module DeploySpecExtension
    def group_stacked_pull_requests?
      config('deploy', 'group_stacked_pull_requests') { ShipitStackedPullRequests.enabled_by_default }
    end
  end
end
