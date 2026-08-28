class CreateMetricSnapshots < ActiveRecord::Migration[8.1]
  def change
    create_table :metric_snapshots do |t|
      t.timestamps
      t.references :account, null: false, foreign_key: true
      t.string   :metric_name, null: false
      t.decimal  :value, null: false
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
    end
    add_index :metric_snapshots, [ :account_id, :metric_name, :starts_at ]
  end
end
