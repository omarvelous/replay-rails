class AddPublicIds < ActiveRecord::Migration[8.1]
  def change
    %i[listings agents ads leads playlists screens sites
       experiences qr_codes screen_contents
       playlist_ads listing_ads agent_ads brand_ads
       collection_ads collection_ad_ads listing_experiences
       listing_agents lead_agents screen_players].each do |table|
      add_column table, :public_id, :uuid, default: "gen_random_uuid()", null: false
      add_index table, :public_id, unique: true
    end
  end
end
