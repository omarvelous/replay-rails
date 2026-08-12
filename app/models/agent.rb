class Agent < ApplicationRecord
  belongs_to :account
  belongs_to :user, optional: true

  has_one_attached :photo do |attachable|
    attachable.variant :thumb, resize_to_fill: [ 200, 200 ]
    attachable.variant :card,  resize_to_fill: [ 400, 400 ]
  end

  has_many :listing_agents, dependent: :destroy
  has_many :listings, through: :listing_agents

  validates :name, presence: true
  validates :email, presence: true
end
