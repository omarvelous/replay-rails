class Current < ActiveSupport::CurrentAttributes
  attribute :session
  attribute :account

  delegate :user, to: :session, allow_nil: true

  def account_user
    membership = user&.account_users&.find_by(account: account)
    return membership if membership

    AdminAccountUser.new if user&.admin? && account
  end
end
