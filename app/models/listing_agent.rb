class ListingAgent < ApplicationRecord
  belongs_to :listing
  belongs_to :agent

  validates :role, presence: true
end
