# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_08_14_124232) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.datetime "updated_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "ads", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "adable_id", null: false
    t.string "adable_type", null: false
    t.text "body"
    t.datetime "created_at", null: false
    t.string "headline", null: false
    t.string "layout", default: "hero", null: false
    t.string "theme", default: "dark", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_ads_on_account_id"
    t.index ["adable_type", "adable_id"], name: "index_ads_on_adable_type_and_adable_id"
  end

  create_table "agent_ads", force: :cascade do |t|
    t.bigint "agent_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["agent_id"], name: "index_agent_ads_on_agent_id"
  end

  create_table "agents", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "name", null: false
    t.string "phone"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["account_id"], name: "index_agents_on_account_id"
    t.index ["user_id"], name: "index_agents_on_user_id"
  end

  create_table "brand_ads", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "collection_ad_ads", force: :cascade do |t|
    t.bigint "ad_id", null: false
    t.bigint "collection_ad_id", null: false
    t.datetime "created_at", null: false
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["ad_id"], name: "index_collection_ad_ads_on_ad_id"
    t.index ["collection_ad_id", "ad_id"], name: "index_collection_ad_ads_on_collection_ad_id_and_ad_id", unique: true
    t.index ["collection_ad_id", "position"], name: "index_collection_ad_ads_on_collection_ad_id_and_position"
    t.index ["collection_ad_id"], name: "index_collection_ad_ads_on_collection_ad_id"
  end

  create_table "collection_ads", force: :cascade do |t|
    t.string "collection_title", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "listing_ads", force: :cascade do |t|
    t.string "badge", default: "just_listed", null: false
    t.datetime "created_at", null: false
    t.date "event_date"
    t.time "event_end_time"
    t.time "event_start_time"
    t.bigint "listing_id", null: false
    t.integer "original_price"
    t.date "sold_date"
    t.integer "sold_price"
    t.datetime "updated_at", null: false
    t.index ["listing_id"], name: "index_listing_ads_on_listing_id"
  end

  create_table "listing_agents", force: :cascade do |t|
    t.bigint "agent_id", null: false
    t.datetime "created_at", null: false
    t.bigint "listing_id", null: false
    t.string "role", default: "listing_agent", null: false
    t.datetime "updated_at", null: false
    t.index ["agent_id"], name: "index_listing_agents_on_agent_id"
    t.index ["listing_id", "agent_id"], name: "index_listing_agents_on_listing_id_and_agent_id", unique: true
    t.index ["listing_id"], name: "index_listing_agents_on_listing_id"
  end

  create_table "listings", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "address", null: false
    t.integer "baths"
    t.integer "beds"
    t.datetime "created_at", null: false
    t.decimal "price", precision: 12, scale: 2, null: false
    t.integer "sqft"
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_listings_on_account_id"
  end

  create_table "players", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "firmware_version"
    t.string "ip_address"
    t.datetime "last_heartbeat_at"
    t.string "pairing_code"
    t.datetime "pairing_code_expires_at"
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.index ["pairing_code"], name: "index_players_on_pairing_code", unique: true
    t.index ["token"], name: "index_players_on_token", unique: true
  end

  create_table "playlist_ads", force: :cascade do |t|
    t.bigint "ad_id", null: false
    t.datetime "created_at", null: false
    t.integer "duration", default: 10, null: false
    t.bigint "playlist_id", null: false
    t.integer "position", null: false
    t.datetime "updated_at", null: false
    t.index ["ad_id"], name: "index_playlist_ads_on_ad_id"
    t.index ["playlist_id", "position"], name: "index_playlist_ads_on_playlist_id_and_position", unique: true
    t.index ["playlist_id"], name: "index_playlist_ads_on_playlist_id"
  end

  create_table "playlists", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "status", default: "draft", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_playlists_on_account_id"
  end

  create_table "qr_codes", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.bigint "destination_record_id"
    t.string "destination_record_type"
    t.string "destination_url"
    t.string "label"
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_qr_codes_on_account_id"
    t.index ["destination_record_type", "destination_record_id"], name: "idx_on_destination_record_type_destination_record_i_017f34d69d"
    t.index ["token"], name: "index_qr_codes_on_token", unique: true
  end

  create_table "qr_scans", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "ad_id"
    t.jsonb "context", default: {}
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.bigint "qr_code_id", null: false
    t.bigint "screen_id"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.index ["account_id"], name: "index_qr_scans_on_account_id"
    t.index ["ad_id"], name: "index_qr_scans_on_ad_id"
    t.index ["qr_code_id", "created_at"], name: "index_qr_scans_on_qr_code_id_and_created_at"
    t.index ["qr_code_id"], name: "index_qr_scans_on_qr_code_id"
    t.index ["screen_id"], name: "index_qr_scans_on_screen_id"
  end

  create_table "screen_players", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.bigint "paired_by_id"
    t.bigint "player_id", null: false
    t.bigint "screen_id", null: false
    t.datetime "unpaired_at"
    t.datetime "updated_at", null: false
    t.index ["paired_by_id"], name: "index_screen_players_on_paired_by_id"
    t.index ["player_id"], name: "idx_screen_players_active_player", unique: true, where: "(active = true)"
    t.index ["player_id"], name: "index_screen_players_on_player_id"
    t.index ["screen_id"], name: "idx_screen_players_active_screen", unique: true, where: "(active = true)"
    t.index ["screen_id"], name: "index_screen_players_on_screen_id"
  end

  create_table "screen_playlists", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.bigint "playlist_id", null: false
    t.bigint "screen_id", null: false
    t.datetime "updated_at", null: false
    t.index ["playlist_id"], name: "index_screen_playlists_on_playlist_id"
    t.index ["screen_id", "playlist_id"], name: "index_screen_playlists_on_screen_id_and_playlist_id", unique: true
    t.index ["screen_id"], name: "index_screen_playlists_on_screen_id"
  end

  create_table "screens", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "orientation", default: "landscape", null: false
    t.bigint "site_id", null: false
    t.datetime "updated_at", null: false
    t.index ["site_id"], name: "index_screens_on_site_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "sites", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "address"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_sites_on_account_id"
  end

  create_table "users", force: :cascade do |t|
    t.bigint "account_id"
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "password_digest", null: false
    t.string "phone"
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_users_on_account_id"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "ads", "accounts"
  add_foreign_key "agent_ads", "agents"
  add_foreign_key "agents", "accounts"
  add_foreign_key "agents", "users"
  add_foreign_key "collection_ad_ads", "ads"
  add_foreign_key "collection_ad_ads", "collection_ads"
  add_foreign_key "listing_ads", "listings"
  add_foreign_key "listing_agents", "agents"
  add_foreign_key "listing_agents", "listings"
  add_foreign_key "listings", "accounts"
  add_foreign_key "playlist_ads", "ads"
  add_foreign_key "playlist_ads", "playlists"
  add_foreign_key "playlists", "accounts"
  add_foreign_key "qr_codes", "accounts"
  add_foreign_key "qr_scans", "accounts"
  add_foreign_key "qr_scans", "ads"
  add_foreign_key "qr_scans", "qr_codes"
  add_foreign_key "qr_scans", "screens"
  add_foreign_key "screen_players", "players"
  add_foreign_key "screen_players", "screens"
  add_foreign_key "screen_players", "users", column: "paired_by_id"
  add_foreign_key "screen_playlists", "playlists"
  add_foreign_key "screen_playlists", "screens"
  add_foreign_key "screens", "sites"
  add_foreign_key "sessions", "users"
  add_foreign_key "sites", "accounts"
  add_foreign_key "users", "accounts"
end
