class Inquiry < ApplicationRecord
  TYPES = %w[demo_request general].freeze

  validates :name, presence: true
  validates :email, presence: true
  validates :inquiry_type, inclusion: { in: TYPES }
end
