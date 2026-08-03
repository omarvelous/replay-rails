class CreateAds < ActiveRecord::Migration[8.1]
  def change
    create_table :ads do |t|
      t.timestamps
      t.references :account, null: false, foreign_key: true
      t.references :listing, null: true, foreign_key: true
      t.string :headline, null: false
      t.text :body
    end
  end
end
