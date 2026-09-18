class DropImpressionsTableAndPlayerToken < ActiveRecord::Migration[8.1]
  def change
    drop_table :impressions do |t|
      t.timestamps
      t.bigint :account_id, null: false
      t.bigint :ad_id, null: false
      t.bigint :player_id, null: false
      t.bigint :screen_id, null: false
      t.bigint :site_id, null: false
      t.bigint :playlist_id
      t.integer :position
      t.integer :duration
    end

    remove_index :players, :token
    remove_column :players, :token, :string
  end
end
