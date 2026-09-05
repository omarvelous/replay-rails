class CreateExperiences < ActiveRecord::Migration[8.1]
  def change
    create_table :experiences do |t|
      t.timestamps
      t.references :account, null: false, foreign_key: true
      t.string :experienceable_type, null: false
      t.bigint :experienceable_id, null: false
      t.string :name, null: false
      t.jsonb :config, null: false, default: {}
      t.index [ :experienceable_type, :experienceable_id ]
    end

    create_table :listing_experiences do |t|
      t.timestamps
      t.references :listing, null: false, foreign_key: true
      t.references :agent, foreign_key: true
    end
  end
end
