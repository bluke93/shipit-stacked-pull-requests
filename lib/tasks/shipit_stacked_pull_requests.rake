# frozen_string_literal: true

namespace :shipit_stacked_pull_requests do
  desc 'Fetch the pull request stack of the undeployed commits of every stack that groups stacked pull requests'
  task backfill: :environment do
    Shipit::Stack.not_archived.find_each do |stack|
      next unless stack.group_stacked_pull_requests?

      commits = stack.undeployed_commits
      commits.each { |commit| ShipitStackedPullRequests::FetchPullRequestStackJob.perform_later(commit) }
      puts "#{stack.to_param}: scheduled #{commits.size} commits"
    end
  end
end
