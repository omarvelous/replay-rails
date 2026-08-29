class Ad < ApplicationRecord
  has_paper_trail ignore: [ :updated_at ]
  acts_as_tenant :account
  delegated_type :adable, types: %w[Ads::ListingAd Ads::CollectionAd Ads::AgentAd Ads::BrandAd], dependent: :destroy

  THEMES = %w[dark light brand].freeze

  has_many :playlist_ads, dependent: :destroy
  has_many :playlists, through: :playlist_ads
  has_many :collection_ad_ads, class_name: "Ads::CollectionAdAd", dependent: :restrict_with_error

  has_one_attached :image do |attachable|
    attachable.variant :thumb,   resize_to_fill: [ 400, 225 ]
    attachable.variant :preview, resize_to_fill: [ 1920, 1080 ]
  end

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

  def adable_partial_path
    adable.class.name.underscore.pluralize # "ads/listing_ads"
  end

  def adable_short_name
    adable.class.name.demodulize.underscore # "listing_ad" (no namespace)
  end

  def apply_defaults
    self.headline = adable&.default_headline if headline.blank?
    self.layout = allowed_layouts.first if layout.blank?
    self.theme = "dark" if theme.blank?
  end
end
