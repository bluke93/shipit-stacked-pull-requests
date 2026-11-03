# frozen_string_literal: true

# Example data to try the extension locally: two stacks with GitHub stacked pull requests, a split stack, failing
# and locked pull requests, and previous deploys. Nothing here talks to GitHub.

module Shipit
  Stack.send(:define_method, :sync_github) {}
  Commit.send(:define_method, :fetch_stats!) {}
  Commit.send(:define_method, :refresh_statuses!) {}
  Commit.send(:define_method, :refresh_check_runs!) {}
  Commit.send(:define_method, :fetch_github_pull_request_stack!) {}
  ReleaseStatus.send(:define_method, :create_status_on_github!) {}
  CommitDeployment.send(:define_method, :schedule_create_on_github) {}
  CommitDeploymentStatus.send(:define_method, :schedule_create_on_github) {}

  deploy_spec = DeploySpec.new(
    'ci' => { 'require' => ['ci/travis'] },
    'deploy' => { 'override' => ['bundle exec cap $ENVIRONMENT deploy'], 'max_commits' => 3,
                  'group_stacked_pull_requests' => true },
    'rollback' => { 'override' => ['bundle exec cap $ENVIRONMENT deploy:rollback'] },
    'machine' => { 'environment' => {}, 'directory' => nil }
  )

  users = [
    %w(Sofia\ Rossi srossi), %w(Marco\ Bianchi mbianchi), %w(Giulia\ Conti gconti),
    %w(Ahmed\ Khan akhan), %w(Priya\ Nair pnair),
  ].map do |name, login|
    User.find_or_create_by!(login:) { |user| user.name = name; user.email = "#{login}@example.com" }
  end

  # pull_requests: [number, title, author index, GitHub stack number, CI state, locked], oldest first.
  # deploys: [since PR number, until PR number], since exclusive and until inclusive.
  examples = {
    'payments-api' => {
      pull_requests: [
        [2100, 'Bootstrap payments API', 1, nil, 'success'],
        [2101, 'Payments: add Payment model', 0, 2105, 'success'],
        [2102, 'Payments: add PaymentsController#create', 0, 2105, 'success'],
        [2103, 'Payments: handle Stripe payment webhooks', 0, 2105, 'success'],
        [2104, 'Payments: add payments admin page', 0, 2105, 'success'],
        [2110, 'Bump rack to 3.1.12', 1, nil, 'success'],
        [2121, 'Refunds: add Refund model', 2, 2125, 'success'],
        [2122, 'Refunds: add RefundsController', 2, 2125, 'success'],
        [2123, 'Refunds: emit refund.created webhook', 2, 2125, 'success'],
        [2124, 'Refunds: document the refunds endpoint', 2, 2125, 'success'],
        [2130, 'Fix typo in README', 4, nil, 'success'],
        [2141, 'Currency: add Money value object', 3, 2145, 'success', true],
        [2142, 'Currency: convert amounts with ExchangeRate', 3, 2145, 'failure'],
        [2150, 'Hotfix: raise Stripe API timeout to 30s', 1, nil, 'success'],
        [2143, 'Currency: show converted totals on invoices', 3, 2145, 'success'],
        [2144, 'Currency: backfill currency on old payments', 3, 2145, 'pending'],
        [2146, 'Currency: drop legacy amount_cents columns', 3, 2145, 'success'],
      ],
      deploys: [[2100, 2104], [2104, 2122]],
    },
    'storefront' => {
      pull_requests: [
        [1190, 'Paginate order history API', 0, nil, 'success'],
        [1196, 'Add feature flag for one-click reorder', 1, nil, 'success'],
        [1197, 'Fix flaky CartControllerTest', 2, nil, 'success'],
        [1198, 'Support gift messages on orders', 3, 1210, 'success'],
        [1199, 'Add rate limiting to public storefront API', 4, 1210, 'success'],
        [1200, 'Lazy-load product images below the fold', 0, 1210, 'pending'],
        [1201, 'Bump nokogiri to 1.19.3', 1, nil, 'failure'],
        [1202, 'Add admin view for refunded orders', 2, 1211, 'success'],
        [1203, 'Localise checkout flow for Italian', 3, 1211, 'pending'],
      ],
      deploys: [[1190, 1196], [1196, 1197]],
    },
  }

  examples.each do |name, example|
    repository = Repository.find_or_create_by!(owner: 'acme', name:)
    next if repository.stacks.exists?

    stack = Stack.create!(repository:, environment: 'production', branch: 'main',
                          deploy_url: "https://#{name}.example.com/", cached_deploy_spec: deploy_spec)

    start = 5.days.ago
    commits = example[:pull_requests].each_with_index.to_h do |(number, title, author, stack_number, state, locked), i|
      committed_at = start + (i * 6).hours
      commit = stack.commits.create!(
        author: users[author], committer: users[author], sha: SecureRandom.hex(20),
        message: "Merge pull request ##{number} from acme/#{title.parameterize.first(30)}\n\n#{title}",
        authored_at: committed_at, committed_at:, additions: rand(5..400), deletions: rand(0..150),
        locked: locked || false, lock_author_id: (users[4].id if locked)
      )
      Status.create!(state:, context: 'ci/travis', description: "Build #{state}", target_url: 'https://example.com',
                     commit_id: commit.id, stack_id: stack.id)
      ShipitStackedPullRequests::CommitStack.create!(commit:, stack_number:) if stack_number
      [number, commit]
    end

    example[:deploys].each_with_index do |(since_number, until_number), i|
      since_commit, until_commit = commits.values_at(since_number, until_number)
      shipped = commits.values.select { |commit| commit.id > since_commit.id && commit.id <= until_commit.id }
      started_at = until_commit.committed_at + 30.minutes
      deploy = stack.deploys.create!(
        since_commit:, until_commit:, status: 'success', user: users[i], started_at:,
        ended_at: started_at + 5.minutes, created_at: started_at,
        additions: shipped.sum(&:additions), deletions: shipped.sum(&:deletions)
      )
      deploy.write("$ bundle exec cap production deploy\nDeploying #{shipped.size} pull requests...\nDone.\n")
    end

    stack.update_undeployed_commits_count
    puts "Created /#{stack.to_param}"
  end
end
