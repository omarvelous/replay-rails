class DropScreenPlaylists < ActiveRecord::Migration[8.1]
  def up
    drop_table :screen_playlists
  end

  def down
    create_table :screen_playlists do |t|
      t.timestamps
      t.references :screen, null: false, foreign_key: true
      t.references :playlist, null: false, foreign_key: true
      t.boolean :active, null: false, default: true
    end
  end
end
