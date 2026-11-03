# frozen_string_literal: true

require_relative 'boot'

require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_view/railtie'
require 'active_job/railtie'
require 'rails/test_unit/railtie'
require 'sprockets/railtie'

Bundler.require(*Rails.groups)
require 'shipit'
require 'shipit_stacked_pull_requests'

module Dummy
  # A minimal Shipit host application, set up like the one Shipit's template generates.
  class Application < Rails::Application
    config.load_defaults 8.1
    config.active_record.encryption.support_sha1_for_non_deterministic_encryption = true

    # Host applications install these with `rails railties:install:migrations`.
    config.paths['db/migrate'] << Shipit::Engine.root.join('db/migrate').to_s
    config.paths['db/migrate'] << ShipitStackedPullRequests::Engine.root.join('db/migrate').to_s
  end
end
