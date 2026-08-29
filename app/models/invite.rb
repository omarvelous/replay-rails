class Invite < ApplicationRecord
  has_paper_trail ignore: [ :updated_at ]
  acts_as_tenant :account
  belongs_to :invited_by, class_name: "User"

  ROLES = %w[manager agent].freeze

  before_create :generate_token

  normalizes :email, with: ->(e) { e.strip.downcase }

  validates :email, presence: true
  validates :role, inclusion: { in: ROLES }
  validate :not_already_in_role

  scope :pending, -> { where(accepted_at: nil).where(created_at: 7.days.ago..) }
  scope :expired, -> { where(accepted_at: nil).where(created_at: ...7.days.ago) }

  def pending?
    accepted_at.nil? && created_at > 7.days.ago
  end

  def expired?
    accepted_at.nil? && created_at <= 7.days.ago
  end

  def accepted?
    accepted_at.present?
  end

  def accept!(user)
    transaction do
      update!(accepted_at: Time.current)
      AccountUser.create!(account: account, user: user, role: role)
      link_agent_profile(user) if role == "agent"
    end
  end

  private

  def generate_token
    self.token = SecureRandom.urlsafe_base64(32)
  end

  def not_already_in_role
    existing_user = User.find_by(email_address: email)
    return unless existing_user

    if AccountUser.exists?(account: account, user: existing_user, role: role)
      errors.add(:email, "already has the #{role} role on this account")
    end
  end

  def link_agent_profile(user)
    agent = Agent.find_by(account: account, email: email)
    agent&.update!(user: user) if agent && agent.user_id.nil?
  end
end
