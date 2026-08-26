class CreateCollectionAdAds < ActiveRecord::Migration[8.1]
  def change
    create_table :collection_ad_ads do |t|
      t.timestamps
      t.references :collection_ad, null: false, foreign_key: { to_table: :collection_ads }
      t.references :ad,            null: false, foreign_key: true
      t.integer    :position,      null: false, default: 0
    end
    add_index :collection_ad_ads, %i[collection_ad_id ad_id], unique: true
    add_index :collection_ad_ads, %i[collection_ad_id position]
  end
end
