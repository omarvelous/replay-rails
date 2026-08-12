class CreateListingAds < ActiveRecord::Migration[8.1]
  def change
    create_table :listing_ads do |t|
      t.timestamps
      t.references :listing, null: false, foreign_key: true
      t.string  :badge, null: false, default: "just_listed"
      t.date    :event_date
      t.time    :event_start_time
      t.time    :event_end_time
      t.integer :original_price
      t.integer :sold_price
      t.date    :sold_date
    end
  end
end
