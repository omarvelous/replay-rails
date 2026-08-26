class CreateLeads < ActiveRecord::Migration[8.1]
  def change
    create_table :leads do |t|
      t.timestamps
      t.references :account, null: false, foreign_key: true
      t.references :qr_scan, foreign_key: true
      t.string  :lead_type, null: false, default: "general_inquiry"
      t.string  :status, null: false, default: "new"
      t.string  :name, null: false
      t.string  :email
      t.string  :phone
      t.text    :message
      t.jsonb   :context, default: {}
    end
    add_index :leads, [ :account_id, :status ]
    add_index :leads, [ :account_id, :created_at ]
  end
end
