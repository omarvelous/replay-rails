module Authorizable
  extend ActiveSupport::Concern

  def membership_on(account)
    account_users.find_by(account: account)
  end

  def member_of?(account)
    membership_on(account).present?
  end

  def owner_of?(account)
    membership_on(account)&.role == "owner"
  end

  def can_manage?(account)
    membership_on(account)&.at_least?("manager") || false
  end
end
