class Account < ApplicationRecord
  has_many :account_users, dependent: :destroy
  has_many :users, through: :account_users
  has_many :sites, dependent: :destroy
  has_many :screens, through: :sites
  has_many :listings, dependent: :destroy
  has_many :agents, dependent: :destroy
  has_many :listing_agents, through: :listings
  has_many :ads, dependent: :destroy
  has_many :playlists, dependent: :destroy
  has_many :playlist_ads, through: :playlists
  has_many :qr_codes, dependent: :destroy
  has_many :leads, dependent: :destroy
end
