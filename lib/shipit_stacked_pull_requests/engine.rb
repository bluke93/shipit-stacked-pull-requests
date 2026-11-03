# frozen_string_literal: true

module ShipitStackedPullRequests
  class Engine < ::Rails::Engine
    isolate_namespace ShipitStackedPullRequests

    # This engine is initialized after Shipit's, so its views (the stack page, commit and deploy rows)
    # take precedence over Shipit's own. The host application's views still take precedence over both.

    initializer 'shipit_stacked_pull_requests.assets' do |app|
      app.config.assets.precompile += %w[shipit_stacked_pull_requests.js shipit_stacked_pull_requests.css]
    end

    initializer 'shipit_stacked_pull_requests.routes' do |app|
      app.routes.prepend do
        mount ShipitStackedPullRequests::Engine, at: ShipitStackedPullRequests.mount_path
      end
    end

    config.to_prepare do
      Shipit::DeploySpec.include(ShipitStackedPullRequests::DeploySpecExtension)
      Shipit::Stack.include(ShipitStackedPullRequests::StackExtension)
      Shipit::Commit.include(ShipitStackedPullRequests::CommitExtension)
      Shipit::StacksController.prepend(ShipitStackedPullRequests::StacksControllerExtension)
    end
  end
end
