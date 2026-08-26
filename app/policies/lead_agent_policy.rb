class LeadAgentPolicy < ApplicationPolicy
  def new?    = account_user.can_manage?
  def create? = account_user.can_manage?
end
