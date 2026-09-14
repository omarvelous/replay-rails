class Session < ApplicationRecord
  include PublicIdentifiable

  belongs_to :user
end
