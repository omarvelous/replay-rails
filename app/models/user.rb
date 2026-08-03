class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  belongs_to :account

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :first_name, :last_name, presence: true
  validates :email_address, presence: true, uniqueness: { case_sensitive: false }
  validates :phone, format: { with: /\A[\d\s\-\+\(\)]+\z/, message: "is not a valid phone number" }, allow_blank: true
end
