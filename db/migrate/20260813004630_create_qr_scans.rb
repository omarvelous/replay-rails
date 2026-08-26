class CreateQrScans < ActiveRecord::Migration[8.1]
  def change
    create_table :qr_scans do |t|
      t.timestamps
      t.references :qr_code, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true
      t.string :source_type
      t.bigint :source_id
      t.string :ip_address
      t.string :user_agent
    end
    add_index :qr_scans, [ :qr_code_id, :created_at ]
    add_index :qr_scans, [ :source_type, :source_id ]
  end
end
