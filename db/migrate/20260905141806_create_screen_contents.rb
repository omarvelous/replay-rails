class CreateScreenContents < ActiveRecord::Migration[8.1]
  def change
    create_table :screen_contents do |t|
      t.timestamps
      t.references :screen, null: false, foreign_key: true
      t.string :contentable_type, null: false
      t.bigint :contentable_id, null: false
      t.boolean :active, null: false, default: true
      t.index [ :contentable_type, :contentable_id ]
      t.index [ :screen_id ], unique: true, where: "active = true", name: "idx_screen_contents_one_active_per_screen"
    end
  end
end
