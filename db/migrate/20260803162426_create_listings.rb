class CreateListings < ActiveRecord::Migration[8.1]
  def change
    create_table :listings do |t|
      t.timestamps
      t.references :account, null: false, foreign_key: true
      t.string :address, null: false
      t.decimal :price, precision: 12, scale: 2, null: false
      t.integer :beds
      t.integer :baths
      t.integer :sqft
      t.string :status, null: false, default: "active"
    end
  end
end
