# frozen_string_literal: true

require 'shipit'
require 'shipit_stacked_pull_requests/version'
require 'shipit_stacked_pull_requests/engine'

module ShipitStackedPullRequests
  class << self
    # Whether stacks group stacked pull requests when their `shipit.yml` doesn't set
    # `deploy.group_stacked_pull_requests`. Set it to `true` to enable the feature on every stack.
    attr_accessor :enabled_by_default

    # Where the extension's own routes are mounted in the host application.
    attr_accessor :mount_path
  end

  self.enabled_by_default = false
  self.mount_path = '/stacked_pull_requests'
end
