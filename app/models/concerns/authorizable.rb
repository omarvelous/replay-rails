module Authorizable
  extend ActiveSupport::Concern

  def roles_on(account)
    account_users.where(account: account).pluck(:role)
  end

  def has_role?(role, account)
    account_users.exists?(account: account, role: role)
  end

  def owner_of?(account)
    has_role?("owner", account)
  end

  def can_manage?(account)
    account_users.exists?(account: account, role: %w[owner manager])
  end

  def agent_on?(account)
    has_role?("agent", account)
  end

  def member_of?(account)
    account_users.exists?(account: account)
  end
end
