class AddCreativeAndScreenContentToQrCodes < ActiveRecord::Migration[8.1]
  def change
    add_reference :qr_codes, :creative, polymorphic: true, null: true
    add_reference :qr_codes, :screen_content, foreign_key: true, null: true

    add_index :qr_codes,
      [ :destination_record_type, :destination_record_id, :creative_type, :creative_id, :screen_content_id ],
      unique: true,
      name: :idx_qr_codes_on_destination_creative_screen_content
  end
end
