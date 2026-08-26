class Current < ActiveSupport::CurrentAttributes
  attribute :session
  attribute :account

  delegate :user, to: :session, allow_nil: true

  def account
    super || user&.accounts&.first
  end
end
