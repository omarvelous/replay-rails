class ListingPolicy < ApplicationPolicy
  def show?
    account_user.can_manage? || owns_listing?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if account_user.can_manage?
        scope.all
      else
        scope.joins(:listing_agents)
             .where(listing_agents: { agent_id: agent_id })
      end
    end

    private

    def agent_id
      account_user.user.agent_profile&.id
    end
  end

  private

  def owns_listing?
    record.listing_agents.exists?(agent_id: account_user.user.agent_profile&.id)
  end
end
