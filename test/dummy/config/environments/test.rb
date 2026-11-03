# frozen_string_literal: true

Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true

  config.public_file_server.enabled = true
  config.consider_all_requests_local = true
  config.action_controller.perform_caching = false
  config.cache_store = :null_store
  config.action_dispatch.show_exceptions = :none
  config.action_controller.allow_forgery_protection = false
  config.active_support.test_order = :random
  config.active_support.deprecation = :stderr

  Shipit.use_git_askpass = false

  config.to_prepare do
    Shipit::DeferredTouch.enabled = false
    # Shipit's fixtures have pretty printed deploy specs, so stacks shouldn't look dirty.
    Shipit::DeploySpec.pretty_generate = true
  end
end
