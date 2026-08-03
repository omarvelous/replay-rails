class Account < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :sites, dependent: :destroy
  has_many :listings, dependent: :destroy
end
