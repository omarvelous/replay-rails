class AddDelegatedTypeToAds < ActiveRecord::Migration[8.1]
  def up
    add_column :ads, :adable_type, :string
    add_column :ads, :adable_id,   :bigint
    add_column :ads, :layout,      :string, null: false, default: "hero"
    add_column :ads, :theme,       :string, null: false, default: "dark"

    # Backfill: create a ListingAd for each existing ad that has a listing_id
    execute <<~SQL
      INSERT INTO listing_ads (created_at, updated_at, listing_id, badge)
      SELECT created_at, updated_at, listing_id, 'just_listed'
      FROM ads
      WHERE listing_id IS NOT NULL
    SQL

    # Link each ad to its new ListingAd via adable
    execute <<~SQL
      UPDATE ads
      SET adable_type = 'ListingAd',
          adable_id = listing_ads.id
      FROM listing_ads
      WHERE ads.listing_id = listing_ads.listing_id
        AND ads.listing_id IS NOT NULL
    SQL

    # For ads without a listing, create a BrandAd
    execute <<~SQL
      INSERT INTO brand_ads (created_at, updated_at)
      SELECT created_at, updated_at
      FROM ads
      WHERE listing_id IS NULL
    SQL

    # Link standalone ads to their BrandAd
    # Use a window function to pair them by creation order
    execute <<~SQL
      WITH standalone_ads AS (
        SELECT id, ROW_NUMBER() OVER (ORDER BY id) AS rn
        FROM ads
        WHERE listing_id IS NULL
      ),
      new_brand_ads AS (
        SELECT id, ROW_NUMBER() OVER (ORDER BY id) AS rn
        FROM brand_ads
      )
      UPDATE ads
      SET adable_type = 'BrandAd',
          adable_id = new_brand_ads.id
      FROM standalone_ads
      JOIN new_brand_ads ON standalone_ads.rn = new_brand_ads.rn
      WHERE ads.id = standalone_ads.id
    SQL

    change_column_null :ads, :adable_type, false
    change_column_null :ads, :adable_id, false
    add_index :ads, [ :adable_type, :adable_id ]

    remove_reference :ads, :listing, foreign_key: true
  end

  def down
    add_reference :ads, :listing, foreign_key: true

    # Restore listing_id from ListingAd records
    execute <<~SQL
      UPDATE ads
      SET listing_id = listing_ads.listing_id
      FROM listing_ads
      WHERE ads.adable_type = 'ListingAd'
        AND ads.adable_id = listing_ads.id
    SQL

    remove_index :ads, [ :adable_type, :adable_id ]
    remove_column :ads, :adable_type
    remove_column :ads, :adable_id
    remove_column :ads, :layout
    remove_column :ads, :theme
  end
end
