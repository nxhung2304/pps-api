class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    enable_extension 'pgcrypto' unless extension_enabled?('pgcrypto')

    create_table :users do |t|
      t.string :email
      t.string :password_digest

      t.timestamps
    end

    add_index :users, :email
  end
end
