class CreateLeadAgents < ActiveRecord::Migration[8.1]
  def change
    create_table :lead_agents do |t|
      t.timestamps
      t.references :lead, null: false, foreign_key: true
      t.references :agent, null: false, foreign_key: true
    end
    add_index :lead_agents, [ :lead_id, :created_at ]
  end
end
