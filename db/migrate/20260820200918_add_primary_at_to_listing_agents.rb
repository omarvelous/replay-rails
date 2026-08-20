class AddPrimaryAtToListingAgents < ActiveRecord::Migration[8.1]
  def change
    add_column :listing_agents, :primary_at, :datetime
  end
end
