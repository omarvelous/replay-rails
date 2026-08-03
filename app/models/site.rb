class Site < ApplicationRecord
  belongs_to :account
  has_many :screens, dependent: :destroy

  validates :name, presence: true
end
