class CreateSites < ActiveRecord::Migration[8.1]
  def change
    create_table :sites do |t|
      t.timestamps
      t.references :account, null: false, foreign_key: true
      t.string :name, null: false
      t.string :address
    end
  end
end
