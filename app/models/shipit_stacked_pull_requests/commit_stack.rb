# frozen_string_literal: true

module ShipitStackedPullRequests
  # The GitHub stacked pull request a commit's pull request belongs to.
  class CommitStack < Shipit::Record
    self.table_name = 'shipit_stacked_pull_requests_commit_stacks'

    belongs_to :commit, class_name: 'Shipit::Commit', inverse_of: :github_pull_request_stack

    validates :stack_number, presence: true
  end
end
