# frozen_string_literal: true

require 'test_helper'

module ShipitStackedPullRequests
  class CommitExtensionTest < ActiveSupport::TestCase
    setup do
      @stack = shipit_stacks(:shipit)
      @commit = shipit_commits(:first)
    end

    test "#fetch_github_pull_request_stack! records the stack of the merged pull request" do
      pull_requests = [
        stub(merged_at: nil, stack: stub(number: 12)),
        stub(merged_at: 1.hour.ago, stack: stub(number: 580))
      ]
      Shipit.github.api.expects(:commit_pulls).with(@stack.github_repo_name, @commit.sha).returns(pull_requests)

      @commit.fetch_github_pull_request_stack!

      assert_equal 580, @commit.reload.github_pull_request_stack.stack_number
    end

    test "#fetch_github_pull_request_stack! looks merge commits up by their pull request number" do
      commit = shipit_commits(:fourth)
      Shipit.github.api.expects(:commit_pulls).never
      Shipit.github.api.expects(:pull_request).with(@stack.github_repo_name, 7).returns(stub(stack: stub(number: 580)))

      commit.fetch_github_pull_request_stack!

      assert_equal 580, commit.reload.github_pull_request_stack.stack_number
    end

    test "#fetch_github_pull_request_stack! forgets the stack when the pull request is no longer stacked" do
      stack_pull_requests([@commit])
      pull_requests = [stub(merged_at: 1.hour.ago, stack: nil)]
      Shipit.github.api.expects(:commit_pulls).with(@stack.github_repo_name, @commit.sha).returns(pull_requests)

      @commit.fetch_github_pull_request_stack!

      assert_nil @commit.reload.github_pull_request_stack
    end

    test "#fetch_github_pull_request_stack! refreshes the commit when its stack changes" do
      pull_requests = [stub(merged_at: 1.hour.ago, stack: stub(number: 580))]
      Shipit.github.api.expects(:commit_pulls).returns(pull_requests)
      @commit.expects(:touch).once

      @commit.fetch_github_pull_request_stack!
    end

    test "#fetch_github_pull_request_stack! leaves the commit alone when its stack didn't change" do
      Shipit.github.api.expects(:commit_pulls).returns([])
      @commit.expects(:touch).never

      @commit.fetch_github_pull_request_stack!
    end

    test "creating a commit fetches its pull request stack when the stack groups stacked pull requests" do
      group_stacked_pull_requests(@stack)
      commit = @stack.commits.build(sha: SecureRandom.hex(20), message: 'Ship it', authored_at: Time.now,
                                    committed_at: Time.now)

      assert_enqueued_with(job: FetchPullRequestStackJob, args: [commit]) do
        commit.save!
      end
    end

    test "creating a commit doesn't fetch its pull request stack by default" do
      assert_no_enqueued_jobs(only: FetchPullRequestStackJob) do
        @stack.commits.create!(sha: SecureRandom.hex(20), message: 'Ship it', authored_at: Time.now,
                               committed_at: Time.now)
      end
    end

    test "FetchPullRequestStackJob fetches the commit's pull request stack" do
      @commit.expects(:fetch_github_pull_request_stack!).once
      FetchPullRequestStackJob.new.perform(@commit)
    end
  end
end
