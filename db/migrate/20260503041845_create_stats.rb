class CreateStats < ActiveRecord::Migration[8.1]
  def change
    create_table :stats do |t|
      t.references :user, null: false, foreign_key: true
      t.date :date, null: false
      t.integer :total_coding_time, null: false, default: 0
      t.integer :total_gym_time, null: false, default: 0
      t.float :total_run_distance, null: false, default: 0.0
      t.float :sleep_duration, null: false, default: 0.0
      t.integer :event_count, null: false, default: 0

      t.timestamps
    end

    add_index :stats, [ :user_id, :date ], unique: true
  end
end
