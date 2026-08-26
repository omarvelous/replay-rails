class CreateCollectionAds < ActiveRecord::Migration[8.1]
  def change
    create_table :collection_ads do |t|
      t.timestamps
      t.string :collection_title, null: false
    end
  end
end
