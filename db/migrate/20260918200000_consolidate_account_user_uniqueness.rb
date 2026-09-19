class ConsolidateAccountUserUniqueness < ActiveRecord::Migration[8.1]
  def change
    remove_index :account_users, [ :account_id, :user_id, :role ]
    add_index :account_users, [ :account_id, :user_id ], unique: true
  end
end
