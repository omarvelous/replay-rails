class Experience < ApplicationRecord
  acts_as_tenant :account
  has_paper_trail

  delegated_type :experienceable, types: %w[Experiences::ListingExperience], dependent: :destroy

  has_many :screen_contents, as: :contentable, dependent: :destroy
  has_many :screens, through: :screen_contents

  validates :name, presence: true

  def listing
    experienceable.try(:listing)
  end

  def default_agent
    experienceable.try(:default_agent)
  end
end
