class Impression < ApplicationRecord
  belongs_to :ad
  belongs_to :screen
  belongs_to :player
  belongs_to :site
  belongs_to :playlist, optional: true
  acts_as_tenant :account
end
