# frozen_string_literal: true

class CreateShipitStackedPullRequestsCommitStacks < ActiveRecord::Migration[8.1]
  def change
    create_table(:shipit_stacked_pull_requests_commit_stacks) do |t|
      t.references(:commit, null: false, index: { unique: true })
      t.integer(:stack_number, null: false)
      t.timestamps
    end
  end
end
