class Ad < ApplicationRecord
  belongs_to :account
  belongs_to :listing, optional: true

  validates :headline, presence: true
end
