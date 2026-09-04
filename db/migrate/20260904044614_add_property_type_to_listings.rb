class AddPropertyTypeToListings < ActiveRecord::Migration[8.1]
  def change
    add_column :listings, :property_type, :string, null: false, default: "house"
  end
end
