# frozen_string_literal: true

require 'test_helper'

module ShipitStackedPullRequests
  # The extension overrides these Shipit templates with modified copies of their Shipit 0.45.5 version.
  # When one of these tests fails, Shipit changed the template: port the change to the extension's copy in
  # app/views, then update the digest below.
  class TemplateDriftTest < ActiveSupport::TestCase
    UPSTREAM_DIGESTS = {
      'app/views/shipit/stacks/show.html.erb' => '445bf756c04276017b47f006866f0b08aea20cba9113e79c4b5f22f180e2700f',
      'app/views/shipit/commits/_commit.html.erb' => '1a20e082f44e1ecdfd4331b137296205947469cd6f9c3b8ef974c6adcb0db396',
      'app/views/shipit/deploys/_deploy.html.erb' => '031a472043bb45904dffd68ee7a807c8af89f11fc35976137243f526f53e1827',
      'app/views/layouts/_head.html.erb' => 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
    }.freeze

    UPSTREAM_DIGESTS.each do |path, digest|
      test "Shipit's #{path} matches the version the override is based on" do
        actual = Digest::SHA256.file(Shipit::Engine.root.join(path)).hexdigest
        assert_equal digest, actual, "Shipit changed #{path}: port the change to this extension's copy"
      end
    end
  end
end
