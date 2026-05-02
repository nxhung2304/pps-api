class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events do |t|
      t.references :user, null: false, foreign_key: true
      t.string :type, null: false
      t.bigint :timestamp, null: false
      t.jsonb :payload, null: false, default: {}

      t.timestamps

      t.index [ :user_id, :type, :timestamp ]
      t.index [ :user_id, :timestamp ]
    end
  end
end
