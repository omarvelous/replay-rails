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

ActiveRecord::Schema[8.1].define(version: 2026_09_05_141854) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "account_users", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.string "role", default: "agent", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["account_id", "user_id", "role"], name: "index_account_users_on_account_id_and_user_id_and_role", unique: true
    t.index ["account_id"], name: "index_account_users_on_account_id"
    t.index ["user_id"], name: "index_account_users_on_user_id"
  end

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

  create_table "experiences", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "agent_id"
    t.jsonb "config", default: {}, null: false
    t.datetime "created_at", null: false
    t.bigint "listing_id", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_experiences_on_account_id"
    t.index ["agent_id"], name: "index_experiences_on_agent_id"
    t.index ["listing_id"], name: "index_experiences_on_listing_id"
  end

  create_table "impressions", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "ad_id", null: false
    t.datetime "created_at", null: false
    t.integer "duration"
    t.bigint "player_id", null: false
    t.bigint "playlist_id"
    t.integer "position"
    t.bigint "screen_id", null: false
    t.bigint "site_id", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "created_at"], name: "index_impressions_on_account_id_and_created_at"
    t.index ["account_id"], name: "index_impressions_on_account_id"
    t.index ["ad_id", "created_at"], name: "index_impressions_on_ad_id_and_created_at"
    t.index ["ad_id"], name: "index_impressions_on_ad_id"
    t.index ["player_id", "created_at"], name: "index_impressions_on_player_id_and_created_at"
    t.index ["player_id"], name: "index_impressions_on_player_id"
    t.index ["playlist_id", "created_at"], name: "index_impressions_on_playlist_id_and_created_at"
    t.index ["playlist_id"], name: "index_impressions_on_playlist_id"
    t.index ["screen_id", "created_at"], name: "index_impressions_on_screen_id_and_created_at"
    t.index ["screen_id"], name: "index_impressions_on_screen_id"
    t.index ["site_id", "created_at"], name: "index_impressions_on_site_id_and_created_at"
    t.index ["site_id"], name: "index_impressions_on_site_id"
  end

  create_table "inquiries", force: :cascade do |t|
    t.string "company"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "inquiry_type", default: "demo_request", null: false
    t.string "interest"
    t.text "message"
    t.string "name", null: false
    t.string "phone"
    t.datetime "responded_at"
    t.datetime "updated_at", null: false
  end

  create_table "invites", force: :cascade do |t|
    t.datetime "accepted_at"
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.bigint "invited_by_id", null: false
    t.datetime "resent_at"
    t.string "role", default: "agent", null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "email"], name: "index_invites_on_account_id_and_email"
    t.index ["account_id"], name: "index_invites_on_account_id"
    t.index ["invited_by_id"], name: "index_invites_on_invited_by_id"
    t.index ["token"], name: "index_invites_on_token", unique: true
  end

  create_table "lead_agents", force: :cascade do |t|
    t.bigint "agent_id", null: false
    t.datetime "created_at", null: false
    t.bigint "lead_id", null: false
    t.datetime "updated_at", null: false
    t.index ["agent_id"], name: "index_lead_agents_on_agent_id"
    t.index ["lead_id", "created_at"], name: "index_lead_agents_on_lead_id_and_created_at"
    t.index ["lead_id"], name: "index_lead_agents_on_lead_id"
  end

  create_table "leads", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.jsonb "context", default: {}
    t.datetime "created_at", null: false
    t.string "email"
    t.string "lead_type", default: "general_inquiry", null: false
    t.bigint "listing_id"
    t.text "message"
    t.string "name", null: false
    t.string "phone"
    t.bigint "qr_scan_id"
    t.string "status", default: "new", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "created_at"], name: "index_leads_on_account_id_and_created_at"
    t.index ["account_id", "status"], name: "index_leads_on_account_id_and_status"
    t.index ["account_id"], name: "index_leads_on_account_id"
    t.index ["listing_id"], name: "index_leads_on_listing_id"
    t.index ["qr_scan_id"], name: "index_leads_on_qr_scan_id"
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
    t.datetime "primary_at"
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
    t.text "description"
    t.string "listing_type", default: "for_sale", null: false
    t.decimal "price", precision: 12, scale: 2, null: false
    t.string "property_type", default: "house", null: false
    t.integer "sqft"
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_listings_on_account_id"
  end

  create_table "metric_snapshots", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "ends_at", null: false
    t.string "metric_name", null: false
    t.datetime "starts_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "value", null: false
    t.index ["account_id", "metric_name", "starts_at"], name: "idx_on_account_id_metric_name_starts_at_62dda274d6"
    t.index ["account_id"], name: "index_metric_snapshots_on_account_id"
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

  create_table "screen_contents", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.bigint "contentable_id", null: false
    t.string "contentable_type", null: false
    t.datetime "created_at", null: false
    t.bigint "screen_id", null: false
    t.datetime "updated_at", null: false
    t.index ["contentable_type", "contentable_id"], name: "index_screen_contents_on_contentable_type_and_contentable_id"
    t.index ["screen_id"], name: "idx_screen_contents_one_active_per_screen", unique: true, where: "(active = true)"
    t.index ["screen_id"], name: "index_screen_contents_on_screen_id"
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
    t.boolean "admin", default: false, null: false
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "password_digest", null: false
    t.string "phone"
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  create_table "versions", force: :cascade do |t|
    t.bigint "account_id"
    t.datetime "created_at"
    t.string "event", null: false
    t.bigint "item_id", null: false
    t.string "item_type", null: false
    t.jsonb "object"
    t.jsonb "object_changes"
    t.string "whodunnit"
    t.index ["account_id"], name: "index_versions_on_account_id"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  add_foreign_key "account_users", "accounts"
  add_foreign_key "account_users", "users"
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "ads", "accounts"
  add_foreign_key "agent_ads", "agents"
  add_foreign_key "agents", "accounts"
  add_foreign_key "agents", "users"
  add_foreign_key "collection_ad_ads", "ads"
  add_foreign_key "collection_ad_ads", "collection_ads"
  add_foreign_key "experiences", "accounts"
  add_foreign_key "experiences", "agents"
  add_foreign_key "experiences", "listings"
  add_foreign_key "impressions", "accounts"
  add_foreign_key "impressions", "ads"
  add_foreign_key "impressions", "players"
  add_foreign_key "impressions", "playlists"
  add_foreign_key "impressions", "screens"
  add_foreign_key "impressions", "sites"
  add_foreign_key "invites", "accounts"
  add_foreign_key "invites", "users", column: "invited_by_id"
  add_foreign_key "lead_agents", "agents"
  add_foreign_key "lead_agents", "leads"
  add_foreign_key "leads", "accounts"
  add_foreign_key "leads", "listings"
  add_foreign_key "leads", "qr_scans"
  add_foreign_key "listing_ads", "listings"
  add_foreign_key "listing_agents", "agents"
  add_foreign_key "listing_agents", "listings"
  add_foreign_key "listings", "accounts"
  add_foreign_key "metric_snapshots", "accounts"
  add_foreign_key "playlist_ads", "ads"
  add_foreign_key "playlist_ads", "playlists"
  add_foreign_key "playlists", "accounts"
  add_foreign_key "qr_codes", "accounts"
  add_foreign_key "qr_scans", "accounts"
  add_foreign_key "qr_scans", "ads"
  add_foreign_key "qr_scans", "qr_codes"
  add_foreign_key "qr_scans", "screens"
  add_foreign_key "screen_contents", "screens"
  add_foreign_key "screen_players", "players"
  add_foreign_key "screen_players", "screens"
  add_foreign_key "screen_players", "users", column: "paired_by_id"
  add_foreign_key "screen_playlists", "playlists"
  add_foreign_key "screen_playlists", "screens"
  add_foreign_key "screens", "sites"
  add_foreign_key "sessions", "users"
  add_foreign_key "sites", "accounts"
end
