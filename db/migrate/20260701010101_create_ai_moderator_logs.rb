# frozen_string_literal: true

class CreateAiModeratorLogs < ActiveRecord::Migration[7.2]
  def change
    create_table :ai_moderator_logs do |t|
      t.integer :reviewable_id
      t.string :decision, null: false
      t.string :username
      t.string :title
      t.text :reason
      t.timestamps
    end

    add_index :ai_moderator_logs, :created_at
    add_index :ai_moderator_logs, :reviewable_id
  end
end
