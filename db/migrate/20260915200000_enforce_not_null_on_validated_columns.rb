class EnforceNotNullOnValidatedColumns < ActiveRecord::Migration[8.1]
  def change
    change_column_null :agents, :name, false
    change_column_null :agents, :email, false
    change_column_null :sites, :name, false
    change_column_null :screens, :name, false
    change_column_null :playlists, :name, false
    change_column_null :playlists, :status, false
    change_column_null :leads, :name, false
    change_column_null :experiences, :name, false
    change_column_null :inquiries, :name, false
    change_column_null :inquiries, :email, false
  end
end
