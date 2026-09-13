class RemoveQrScanFromLeadsAndDropQrScans < ActiveRecord::Migration[8.1]
  def change
    remove_reference :leads, :qr_scan, foreign_key: true
    drop_table :qr_scans do |t|
      t.timestamps
      t.references :qr_code, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true
      t.references :ad, foreign_key: true
      t.references :screen, foreign_key: true
      t.references :ahoy_visit, foreign_key: { to_table: :ahoy_visits }
      t.string :ip_address
      t.string :user_agent
      t.jsonb :context, default: {}
    end
  end
end
