class CreatePlayers < ActiveRecord::Migration[8.1]
  def change
    create_table :players do |t|
      t.timestamps
      t.string   :token,                    null: false
      t.string   :pairing_code
      t.datetime :pairing_code_expires_at
      t.datetime :last_heartbeat_at
      t.string   :ip_address
      t.string   :user_agent
      t.string   :firmware_version
    end
    add_index :players, :token, unique: true
    add_index :players, :pairing_code, unique: true
  end
end
