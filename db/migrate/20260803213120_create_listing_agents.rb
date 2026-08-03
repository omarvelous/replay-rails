class CreateListingAgents < ActiveRecord::Migration[8.1]
  def change
    create_table :listing_agents do |t|
      t.timestamps
      t.references :listing, null: false, foreign_key: true
      t.references :agent, null: false, foreign_key: true
      t.string :role, null: false, default: "listing_agent"
    end

    add_index :listing_agents, %i[listing_id agent_id], unique: true
  end
end
