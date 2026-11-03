# frozen_string_literal: true

module ShipitStackedPullRequests
  # Nests the commits of a GitHub stacked pull request under the newest one, since deploying it ships the whole
  # stack. Each list (undeployed and currently deploying) is grouped on its own.
  module StacksControllerExtension
    def show
      super
      return if performed?

      @stacked_commits = Hash.new { |hash, id| hash[id] = [] }
      return unless @stack.group_stacked_pull_requests?

      stack_numbers = CommitStack.where(commit_id: (@active_commits + @undeployed_commits).map(&:id))
                                 .pluck(:commit_id, :stack_number).to_h
      @active_commits = group_pull_request_stacks(@active_commits, stack_numbers)
      @undeployed_commits = group_pull_request_stacks(@undeployed_commits, stack_numbers)
    end

    private

    # Grouping uses the stack number rather than adjacency, because a merge queue can land an unrelated pull
    # request in the middle of a stack.
    def group_pull_request_stacks(commits, stack_numbers)
      newest_by_stack = {}

      commits.reject do |commit|
        next false unless (stack_number = stack_numbers[commit.id])

        if (newest = newest_by_stack[stack_number])
          @stacked_commits[newest.id] << commit
        else
          newest_by_stack[stack_number] = commit
          false
        end
      end
    end
  end
end
