class Listing < ApplicationRecord
  belongs_to :account
  has_many :listing_agents, dependent: :destroy
  has_many :agents, through: :listing_agents

  validates :address, presence: true
  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true, inclusion: { in: %w[active pending sold] }
end
