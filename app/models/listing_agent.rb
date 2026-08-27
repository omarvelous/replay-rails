class ListingAgent < ApplicationRecord
  belongs_to :listing
  belongs_to :agent

  ROLES = %w[listing_agent co_listing_agent].freeze

  validates :role, inclusion: { in: ROLES }
  validate :same_account

  scope :primary, -> { where.not(primary_at: nil).order(primary_at: :desc) }

  private

    def same_account
      return unless listing && agent
      return if listing.account_id == agent.account_id

      errors.add(:agent, "not found")
    end
end
