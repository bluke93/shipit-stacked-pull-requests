# frozen_string_literal: true

module ShipitStackedPullRequests
  module CommitExtension
    extend ActiveSupport::Concern

    included do
      has_one :github_pull_request_stack, class_name: 'ShipitStackedPullRequests::CommitStack',
                                          dependent: :delete, inverse_of: :commit

      after_commit :schedule_github_pull_request_stack_fetch, on: :create
    end

    def schedule_github_pull_request_stack_fetch
      FetchPullRequestStackJob.perform_later(self) if stack.group_stacked_pull_requests?
    end

    # Records the stack of the merged pull request that introduced the commit, if it was part of a
    # GitHub stacked pull request.
    def fetch_github_pull_request_stack!
      stack_number = github_merged_pull_request&.stack&.number
      return if stack_number == github_pull_request_stack&.stack_number

      if stack_number
        (github_pull_request_stack || build_github_pull_request_stack).update!(stack_number:)
      else
        github_pull_request_stack.destroy!
      end
      touch # Refreshes the stack page of anyone looking at it.
    end

    private

    # Merge commits name their pull request. For other commits, GitHub only lists the merged pull request
    # when the commit is on the default branch.
    def github_merged_pull_request
      if pull_request?
        stack.github_api.pull_request(github_repo_name, pull_request_number)
      else
        stack.github_api.commit_pulls(github_repo_name, sha).find(&:merged_at)
      end
    end
  end
end
