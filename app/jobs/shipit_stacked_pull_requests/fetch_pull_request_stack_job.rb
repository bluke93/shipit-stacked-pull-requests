# frozen_string_literal: true

module ShipitStackedPullRequests
  class FetchPullRequestStackJob < Shipit::BackgroundJob
    queue_as :default

    def perform(commit)
      commit.fetch_github_pull_request_stack!
    end
  end
end
