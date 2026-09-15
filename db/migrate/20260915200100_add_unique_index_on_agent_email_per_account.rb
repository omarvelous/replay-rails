class AddUniqueIndexOnAgentEmailPerAccount < ActiveRecord::Migration[8.1]
  def change
    add_index :agents, [ :account_id, :email ], unique: true
  end
end
