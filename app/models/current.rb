class Current < ActiveSupport::CurrentAttributes
  attribute :session
  attribute :account

  delegate :user, to: :session, allow_nil: true

  def account_user
    user&.account_users&.find_by(account: account)
  end
end
