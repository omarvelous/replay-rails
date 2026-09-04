class Lead < ApplicationRecord
  has_paper_trail ignore: [ :updated_at ]
  acts_as_tenant :account

  TYPES = %w[
    buyer_inquiry
    renter_inquiry
    seller_inquiry
    open_house_rsvp
    general_inquiry
    agent_recruitment
  ].freeze

  STATUSES = %w[new contacted qualified closed].freeze

  belongs_to :listing, optional: true
  belongs_to :qr_scan, optional: true
  has_many :lead_agents, dependent: :destroy
  has_many :agents, through: :lead_agents

  validates :name, presence: true
  validates :email, presence: true, unless: -> { phone.present? }
  validates :phone, presence: true, unless: -> { email.present? }
  validates :lead_type, inclusion: { in: TYPES }
  validates :status, inclusion: { in: STATUSES }
  validates :account, presence: true

  scope :unread, -> { where(status: "new") }
  scope :by_status, ->(s) { where(status: s) }
  scope :search, ->(q) { where("leads.name ILIKE :q OR leads.email ILIKE :q", q: "%#{sanitize_sql_like(q)}%") }

  def current_agent
    agents.order("lead_agents.created_at DESC").first
  end
end
