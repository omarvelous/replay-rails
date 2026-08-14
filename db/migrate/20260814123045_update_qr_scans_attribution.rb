class UpdateQrScansAttribution < ActiveRecord::Migration[8.1]
  def change
    remove_index  :qr_scans, [ :source_type, :source_id ]
    remove_column :qr_scans, :source_type, :string
    remove_column :qr_scans, :source_id, :bigint

    add_reference :qr_scans, :ad, foreign_key: true
    add_reference :qr_scans, :screen, foreign_key: true
    add_column    :qr_scans, :context, :jsonb, default: {}
  end
end
