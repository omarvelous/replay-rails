class CreateExperiences < ActiveRecord::Migration[8.1]
  def change
    create_table :experiences do |t|
      t.timestamps
      t.references :account, null: false, foreign_key: true
      t.references :listing, null: false, foreign_key: true
      t.references :agent, foreign_key: true
      t.string :name
      t.jsonb :config, null: false, default: {}
    end
  end
end
