class CreatePlaylistAds < ActiveRecord::Migration[8.1]
  def change
    create_table :playlist_ads do |t|
      t.timestamps
      t.references :playlist, null: false, foreign_key: true
      t.references :ad, null: false, foreign_key: true
      t.integer :position, null: false
      t.integer :duration, null: false, default: 10
    end

    add_index :playlist_ads, %i[playlist_id position], unique: true
  end
end
