class RemoveAccountIdFromAhoyTables < ActiveRecord::Migration[8.1]
  def change
    remove_column :ahoy_visits, :account_id, :bigint
    remove_column :ahoy_events, :account_id, :bigint
  end
end
