class ListingAd < ApplicationRecord
  BADGES  = %w[just_listed open_house just_sold price_reduction coming_soon].freeze
  LAYOUTS = %w[hero split minimal stat_grid].freeze

  BADGE_LABELS = {
    "just_listed"     => "Just Listed",
    "open_house"      => "Open House",
    "just_sold"       => "Just Sold",
    "price_reduction" => "Price Reduced",
    "coming_soon"     => "Coming Soon"
  }.freeze

  has_one :ad, as: :adable, dependent: :destroy, touch: true

  belongs_to :listing

  validates :badge, inclusion: { in: BADGES }
  validates :listing, presence: true

  with_options if: :open_house? do
    validates :event_date,       presence: true
    validates :event_start_time, presence: true
  end

  with_options if: :price_reduction? do
    validates :original_price, presence: true, numericality: { greater_than: 0 }
  end

  with_options if: :just_sold? do
    validates :sold_price, presence: true, numericality: { greater_than: 0 }
  end

  def default_headline = BADGE_LABELS[badge]
  def badge_label      = BADGE_LABELS[badge]

  def open_house?      = badge == "open_house"
  def just_sold?       = badge == "just_sold"
  def price_reduction? = badge == "price_reduction"
  def coming_soon?     = badge == "coming_soon"
  def just_listed?     = badge == "just_listed"
end
