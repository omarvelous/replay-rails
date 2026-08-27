class CreateImpressions < ActiveRecord::Migration[8.1]
  def change
    create_table :impressions do |t|
      t.timestamps
      t.references :ad, null: false, foreign_key: true
      t.references :screen, null: false, foreign_key: true
      t.references :player, null: false, foreign_key: true
      t.references :site, null: false, foreign_key: true
      t.references :playlist, foreign_key: true
      t.references :account, null: false, foreign_key: true
      t.integer :position
      t.integer :duration
    end
    add_index :impressions, [ :account_id, :created_at ]
    add_index :impressions, [ :ad_id, :created_at ]
    add_index :impressions, [ :screen_id, :created_at ]
    add_index :impressions, [ :player_id, :created_at ]
    add_index :impressions, [ :site_id, :created_at ]
    add_index :impressions, [ :playlist_id, :created_at ]
  end
end
