class User < ApplicationRecord
  include Authorizable

  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :account_users, dependent: :destroy
  has_many :accounts, through: :account_users

  has_one :agent_profile, class_name: "Agent", foreign_key: :user_id

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :first_name, :last_name, presence: true
  validates :email_address, presence: true, uniqueness: { case_sensitive: false }
  validates :phone, format: { with: /\A[\d\s\-\+\(\)]+\z/, message: "is not a valid phone number" }, allow_blank: true
end
