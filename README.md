# shipit-stacked-pull-requests

A [Shipit](https://github.com/Shopify/shipit-engine) extension for teams using [GitHub stacked pull requests](https://docs.github.com/en/pull-requests/get-started/about-stacked-prs).

On a stack page it:

- **Groups stacked pull requests:** the undeployed and currently deploying commits of the same GitHub stack are nested under the newest one. That one keeps its deploy button, which ships the whole stack, and gets a "Stack of N" pill to expand or collapse the earlier ones. A warning such as "1 failing · 1 locked" tells you when a nested pull request needs attention.
- **Expands previous deploys:** each deploy or rollback can expand to list the commits it shipped or reverted, loaded on demand.

## Requirements

- Shipit 0.45 and Rails 8.1.
- Repositories on github.com, which has native stacked pull requests. GitHub Enterprise Server doesn't support them yet, so nothing is grouped there.
- The GitHub App's "Pull requests: Read" permission, which Shipit's [setup](https://github.com/Shopify/shipit-engine/blob/main/docs/setup.md) already asks for.

## Installation

1. Add the gem to your Shipit application's `Gemfile`, after `shipit-engine`, and run `bundle install`:

   ```ruby
   gem 'shipit-stacked-pull-requests', github: 'bluke93/shipit-stacked-pull-requests'
   ```

2. Install and run its migration, which creates the `shipit_stacked_pull_requests_commit_stacks` table:

   ```sh
   bin/rails railties:install:migrations db:migrate
   ```

3. Choose which stacks group stacked pull requests, either per stack or for every stack:
   - **Per stack:** add the option to the stack's `shipit.yml`.

     ```yaml
     deploy:
       group_stacked_pull_requests: true
     ```

   - **For every stack:** turn it on in an initializer. A `shipit.yml` can still opt out with `false`.

     ```ruby
     # config/initializers/shipit_stacked_pull_requests.rb
     ShipitStackedPullRequests.enabled_by_default = true
     ```

4. Optionally, fetch the stacks of the commits that are already undeployed. New commits are fetched as Shipit syncs them.

   ```sh
   bin/rails shipit_stacked_pull_requests:backfill
   ```

The extension mounts its own routes at `/stacked_pull_requests`. To use another path, set `ShipitStackedPullRequests.mount_path` in an initializer.

If your application already has its own `app/views/layouts/_head.html.erb`, that file replaces the extension's, so render the extension's assets from it:

```erb
<%= render 'shipit_stacked_pull_requests/assets' %>
```

## How it works

- **Fetching the stack:** when Shipit syncs a commit on a stack that groups stacked pull requests, `ShipitStackedPullRequests::FetchPullRequestStackJob` asks GitHub which merged pull request introduced it.
  - Merge commits name their pull request, so they're looked up with `GET /repos/{owner}/{repo}/pulls/{number}`.
  - Other commits use `GET /repos/{owner}/{repo}/commits/{sha}/pulls`, which only lists the merged pull request for commits on the default branch.
  - The pull request's `stack.number` is stored in the extension's own table. That's one extra API request per synced commit.
- **Grouping:** commits are grouped by stack number rather than by position, because a merge queue can land an unrelated pull request in the middle of a stack.
- **Templates:** the extension replaces three Shipit templates with modified copies: the stack page, the commit row and the deploy row. Your application's own views still take precedence over the extension's.
- **Shipit's classes:** it extends `Shipit::Commit`, `Shipit::Stack`, `Shipit::DeploySpec` and `Shipit::StacksController` from a `to_prepare` hook.
- **Live updates:** stack pages keep the panels you opened or closed when Shipit refreshes them.

## Upgrading Shipit

The extension's copies of Shipit's templates are based on Shipit 0.45.5. `test/template_drift_test.rb` fails when Shipit changes one of them. When that happens, port the change to the copy in `app/views/shipit/`, then update the digest in the test.

If Shipit adds this feature natively, remove the gem. It reads the same `deploy.group_stacked_pull_requests` option, so `shipit.yml` files keep working.

## Uninstalling

Remove the gem, then drop the `shipit_stacked_pull_requests_commit_stacks` table with a migration. Shipit's own tables aren't modified.

## Development

The test suite runs a small Shipit application in `test/dummy` against Shipit's own fixtures. Those come with Shipit's source, so Bundler installs Shipit from GitHub, or from a local checkout set with `SHIPIT_ENGINE_PATH`.

Tests need Redis, at `REDIS_URL` (default `redis://127.0.0.1:6379/7`):

```sh
bundle install
bundle exec rake test
```

To try the extension in a browser:

```sh
cd test/dummy
bin/rails db:migrate db:seed
SHIPIT_DISABLE_AUTH=1 bin/rails server -p 3018
```

Then open http://localhost:3018/acme/payments-api/production.

## License

MIT, like Shipit. See [LICENSE.txt](LICENSE.txt).
