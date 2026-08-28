class Listing < ApplicationRecord
  has_paper_trail ignore: [ :updated_at ]
  belongs_to :account
  has_many_attached :photos do |attachable|
    attachable.variant :thumb, resize_to_fill: [ 400, 225 ]
    attachable.variant :card,  resize_to_fill: [ 800, 450 ]
  end

  has_one :qr_code, as: :destination_record, dependent: :destroy

  has_many :listing_agents, dependent: :destroy
  has_many :agents, through: :listing_agents
  has_many :listing_ads, class_name: "Ads::ListingAd", dependent: :destroy
  has_many :ads, through: :listing_ads
  has_many :leads, dependent: :nullify

  def primary_agent
    listing_agents.primary.first&.agent || agents.first
  end

  validates :address, presence: true
  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true, inclusion: { in: %w[active pending sold] }

  def ensure_qr_code!
    qr_code || create_qr_code!(account: account, label: address.truncate(40))
  end

  scope :search, ->(q) { where("listings.address ILIKE ?", "%#{sanitize_sql_like(q)}%") }
  scope :by_status, ->(s) { where(status: s) }
end
