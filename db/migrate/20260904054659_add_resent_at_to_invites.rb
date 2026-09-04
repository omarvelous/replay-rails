class AddResentAtToInvites < ActiveRecord::Migration[8.1]
  def change
    add_column :invites, :resent_at, :datetime
  end
end
