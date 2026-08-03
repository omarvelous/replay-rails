class Agent < ApplicationRecord
  belongs_to :account
  belongs_to :user, optional: true
  has_many :listing_agents, dependent: :destroy
  has_many :listings, through: :listing_agents

  validates :name, presence: true
  validates :email, presence: true
end
