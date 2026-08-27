class AllowMultipleRolesPerAccountUser < ActiveRecord::Migration[8.1]
  def change
    remove_index :account_users, [ :account_id, :user_id ]
    add_index :account_users, [ :account_id, :user_id, :role ], unique: true
  end
end
