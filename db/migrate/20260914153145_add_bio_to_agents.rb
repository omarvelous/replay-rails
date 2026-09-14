class AddBioToAgents < ActiveRecord::Migration[8.1]
  def change
    add_column :agents, :bio, :text
  end
end
