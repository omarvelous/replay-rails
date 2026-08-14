class CreateScreenPlayers < ActiveRecord::Migration[8.1]
  def change
    create_table :screen_players do |t|
      t.timestamps
      t.references :screen, null: false, foreign_key: true
      t.references :player, null: false, foreign_key: true
      t.references :paired_by, foreign_key: { to_table: :users }
      t.boolean    :active, null: false, default: true
      t.datetime   :unpaired_at
    end
    add_index :screen_players, :screen_id, where: "active = true", unique: true,
              name: "idx_screen_players_active_screen"
    add_index :screen_players, :player_id, where: "active = true", unique: true,
              name: "idx_screen_players_active_player"
  end
end
