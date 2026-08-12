class Ad < ApplicationRecord
  belongs_to :account
  delegated_type :adable, types: %w[ListingAd CollectionAd AgentAd BrandAd], dependent: :destroy

  has_one_attached :image do |attachable|
    attachable.variant :thumb,   resize_to_fill: [ 400, 225 ]
    attachable.variant :preview, resize_to_fill: [ 1920, 1080 ]
  end

  has_many :playlist_ads, dependent: :destroy
  has_many :playlists, through: :playlist_ads
  has_many :collection_ad_ads, dependent: :restrict_with_error

  THEMES = %w[dark light brand].freeze

  validates :headline, presence: true
  validates :theme, inclusion: { in: THEMES }
  validates :layout, inclusion: { in: ->(ad) { ad.allowed_layouts } }

  scope :search, ->(q) { where("ads.headline ILIKE ?", "%#{sanitize_sql_like(q)}%") }

  # Convenience delegation for views during migration to layout partials
  def listing
    adable.try(:listing)
  end

  def allowed_layouts
    adable ? adable.class::LAYOUTS : %w[hero]
  end

  def apply_defaults
    self.headline = adable&.default_headline if headline.blank?
    self.layout = allowed_layouts.first if layout.blank?
    self.theme = "dark" if theme.blank?
  end
end
