class CreateAgentAds < ActiveRecord::Migration[8.1]
  def change
    create_table :agent_ads do |t|
      t.timestamps
      t.references :agent, null: false, foreign_key: true
    end
  end
end
