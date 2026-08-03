class CreatePlaylists < ActiveRecord::Migration[8.1]
  def change
    create_table :playlists do |t|
      t.timestamps
      t.references :account, null: false, foreign_key: true
      t.string :name, null: false
      t.string :status, null: false, default: "draft"
    end
  end
end
