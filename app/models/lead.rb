class Lead < ApplicationRecord
  belongs_to :account
  belongs_to :qr_scan, optional: true

  has_many :lead_agents, dependent: :destroy
  has_many :agents, through: :lead_agents

  TYPES = %w[
    buyer_inquiry
    renter_inquiry
    seller_inquiry
    open_house_rsvp
    general_inquiry
    agent_recruitment
  ].freeze

  STATUSES = %w[new contacted qualified closed].freeze

  validates :name, presence: true
  validates :email, presence: true, unless: -> { phone.present? }
  validates :phone, presence: true, unless: -> { email.present? }
  validates :lead_type, inclusion: { in: TYPES }
  validates :status, inclusion: { in: STATUSES }
  validates :account, presence: true

  scope :unread, -> { where(status: "new") }
  scope :by_status, ->(s) { where(status: s) }

  def current_agent
    agents.order("lead_agents.created_at DESC").first
  end

  def listing
    dest = qr_scan&.qr_code&.destination_record
    return dest if dest.is_a?(Listing)

    Listing.find_by(id: context&.dig("listing_id")) if context&.dig("listing_id")
  end
end
