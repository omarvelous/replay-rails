class CreateScreens < ActiveRecord::Migration[8.1]
  def change
    create_table :screens do |t|
      t.timestamps
      t.references :site, null: false, foreign_key: true
      t.string :name, null: false
      t.string :orientation, null: false, default: "landscape"
    end
  end
end
