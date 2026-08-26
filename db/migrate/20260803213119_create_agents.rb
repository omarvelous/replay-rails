class CreateAgents < ActiveRecord::Migration[8.1]
  def change
    create_table :agents do |t|
      t.timestamps
      t.references :account, null: false, foreign_key: true
      t.references :user, null: true, foreign_key: true
      t.string :name, null: false
      t.string :email, null: false
      t.string :phone
    end
  end
end
