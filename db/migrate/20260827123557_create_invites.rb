class CreateInvites < ActiveRecord::Migration[8.1]
  def change
    create_table :invites do |t|
      t.timestamps
      t.references :account, null: false, foreign_key: true
      t.references :invited_by, null: false, foreign_key: { to_table: :users }
      t.string :email, null: false
      t.string :role, null: false, default: "agent"
      t.string :token, null: false
      t.datetime :accepted_at
    end
    add_index :invites, :token, unique: true
    add_index :invites, [ :account_id, :email ]
  end
end
