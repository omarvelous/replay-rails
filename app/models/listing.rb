class Listing < ApplicationRecord
  belongs_to :account
  has_many_attached :photos do |attachable|
    attachable.variant :thumb, resize_to_fill: [ 400, 225 ]
    attachable.variant :card,  resize_to_fill: [ 800, 450 ]
  end

  has_many :listing_agents, dependent: :destroy
  has_many :agents, through: :listing_agents
  has_many :listing_ads, dependent: :destroy
  has_many :ads, through: :listing_ads

  validates :address, presence: true
  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true, inclusion: { in: %w[active pending sold] }

  scope :search, ->(q) { where("listings.address ILIKE ?", "%#{sanitize_sql_like(q)}%") }
  scope :by_status, ->(s) { where(status: s) }
end
