# frozen_string_literal: true

Rails.application.configure do
  config.enable_reloading = true
  config.eager_load = false

  config.consider_all_requests_local = true
  config.action_controller.perform_caching = false
  config.cache_store = :null_store
  config.active_support.deprecation = :log
  config.active_record.migration_error = :page_load
  config.assets.debug = true
  config.active_job.queue_adapter = :async

  Shipit.use_git_askpass = false
  Pubsubstub.use_persistent_connections = false

  config.to_prepare do
    Shipit::DeferredTouch.enabled = false
  end
end
