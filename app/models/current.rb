class Current < ActiveSupport::CurrentAttributes
  attribute :session
  attribute :account
  attribute :account_user

  delegate :user, to: :session, allow_nil: true

  def account
    super || user&.accounts&.first
  end

  def account_user
    super || user&.account_users&.find_by(account: account)
  end
end
