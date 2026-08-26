class CreateQrCodes < ActiveRecord::Migration[8.1]
  def change
    create_table :qr_codes do |t|
      t.timestamps
      t.references :account, null: false, foreign_key: true
      t.string  :token, null: false
      t.string  :destination_record_type
      t.bigint  :destination_record_id
      t.string  :destination_url
      t.string  :label
      t.boolean :active, null: false, default: true
    end
    add_index :qr_codes, :token, unique: true
    add_index :qr_codes, [ :destination_record_type, :destination_record_id ]
  end
end
