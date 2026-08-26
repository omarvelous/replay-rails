class CreateScreenPlaylists < ActiveRecord::Migration[8.1]
  def change
    create_table :screen_playlists do |t|
      t.timestamps
      t.references :screen, null: false, foreign_key: true
      t.references :playlist, null: false, foreign_key: true
      t.boolean :active, null: false, default: true
    end

    add_index :screen_playlists, %i[screen_id playlist_id], unique: true
  end
end
