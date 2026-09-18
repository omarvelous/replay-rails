class CreatePlayerSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :player_sessions do |t|
      t.timestamps
      t.references :player, null: false, foreign_key: true
      t.string :ip_address
      t.string :user_agent
      t.datetime :last_active_at
      t.datetime :revoked_at
    end
  end
end
