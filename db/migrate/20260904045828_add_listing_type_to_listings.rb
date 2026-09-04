class AddListingTypeToListings < ActiveRecord::Migration[8.1]
  def change
    add_column :listings, :listing_type, :string, null: false, default: "for_sale"
  end
end
