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

ActiveRecord::Schema[8.1].define(version: 2026_08_04_004248) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "ads", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.text "body"
    t.datetime "created_at", null: false
    t.string "headline", null: false
    t.bigint "listing_id"
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_ads_on_account_id"
    t.index ["listing_id"], name: "index_ads_on_listing_id"
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

  add_foreign_key "ads", "accounts"
  add_foreign_key "ads", "listings"
  add_foreign_key "agents", "accounts"
  add_foreign_key "agents", "users"
  add_foreign_key "listing_agents", "agents"
  add_foreign_key "listing_agents", "listings"
  add_foreign_key "listings", "accounts"
  add_foreign_key "playlist_ads", "ads"
  add_foreign_key "playlist_ads", "playlists"
  add_foreign_key "playlists", "accounts"
  add_foreign_key "screen_playlists", "playlists"
  add_foreign_key "screen_playlists", "screens"
  add_foreign_key "screens", "sites"
  add_foreign_key "sessions", "users"
  add_foreign_key "sites", "accounts"
  add_foreign_key "users", "accounts"
end
