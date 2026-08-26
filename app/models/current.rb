class Current < ActiveSupport::CurrentAttributes
  attribute :session
  attribute :account_user

  delegate :user, to: :session, allow_nil: true
  delegate :account, to: :account_user, allow_nil: true
end
