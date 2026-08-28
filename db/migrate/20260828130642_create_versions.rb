class CreateVersions < ActiveRecord::Migration[8.1]
  def change
    create_table :versions do |t|
      t.datetime :created_at
      t.bigint   :item_id,   null: false
      t.string   :item_type, null: false
      t.string   :event,     null: false
      t.string   :whodunnit
      t.jsonb    :object
      t.bigint   :account_id
    end
    add_index :versions, %i[item_type item_id]
    add_index :versions, :account_id
  end
end
