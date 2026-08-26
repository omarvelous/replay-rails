class CreateActiveStorageTables < ActiveRecord::Migration[8.1]
  def change
    create_table :active_storage_blobs do |t|
      t.timestamps
      t.string   :key,          null: false
      t.string   :filename,     null: false
      t.string   :content_type
      t.text     :metadata
      t.string   :service_name, null: false
      t.bigint   :byte_size,    null: false
      t.string   :checksum
    end
    add_index :active_storage_blobs, :key, unique: true

    create_table :active_storage_attachments do |t|
      t.timestamps
      t.string     :name,        null: false
      t.references :record,      null: false, polymorphic: true, index: false
      t.references :blob,        null: false, foreign_key: { to_table: :active_storage_blobs }
    end
    add_index :active_storage_attachments, [ :record_type, :record_id, :name, :blob_id ],
              name: :index_active_storage_attachments_uniqueness, unique: true

    create_table :active_storage_variant_records do |t|
      t.timestamps
      t.belongs_to :blob, null: false, foreign_key: { to_table: :active_storage_blobs },
                          index: false
      t.string :variation_digest, null: false
    end
    add_index :active_storage_variant_records, %i[ blob_id variation_digest ],
              name: :index_active_storage_variant_records_uniqueness, unique: true
  end
end
