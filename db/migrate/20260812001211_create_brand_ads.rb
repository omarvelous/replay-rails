class CreateBrandAds < ActiveRecord::Migration[8.1]
  def change
    create_table :brand_ads do |t|
      t.timestamps
    end
  end
end
