# frozen_string_literal: true

ShipitStackedPullRequests::Engine.routes.draw do
  scope '/*stack_id', stack_id: %r{[^/]+/[^/]+/[^/]+} do
    get '/deploys/:id/commits' => 'deploy_commits#show', as: :deploy_commits
  end
end
