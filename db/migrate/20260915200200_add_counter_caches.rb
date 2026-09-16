class AddCounterCaches < ActiveRecord::Migration[8.1]
  def change
    add_column :playlists, :playlist_ads_count, :integer, default: 0, null: false
    add_column :listings, :listing_agents_count, :integer, default: 0, null: false
  end
end
