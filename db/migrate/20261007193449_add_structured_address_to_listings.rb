class AddStructuredAddressToListings < ActiveRecord::Migration[8.1]
  def change
    add_column :listings, :street, :string
    add_column :listings, :city, :string
    add_column :listings, :state, :string
    add_column :listings, :zip, :string
    add_column :listings, :neighborhood, :string
  end
end
