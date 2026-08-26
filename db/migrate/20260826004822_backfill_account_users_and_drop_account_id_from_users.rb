class BackfillAccountUsersAndDropAccountIdFromUsers < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      INSERT INTO account_users (created_at, updated_at, account_id, user_id, role)
      SELECT NOW(), NOW(), account_id, id, 'owner'
      FROM users
      WHERE account_id IS NOT NULL
        AND NOT EXISTS (
          SELECT 1 FROM account_users WHERE account_users.user_id = users.id
        )
    SQL

    remove_reference :users, :account
  end

  def down
    add_reference :users, :account, foreign_key: true

    execute <<~SQL
      UPDATE users
      SET account_id = (
        SELECT account_id FROM account_users
        WHERE account_users.user_id = users.id
        ORDER BY account_users.created_at ASC
        LIMIT 1
      )
    SQL
  end
end
