module Agents
  class ListingAgentsController < ::ListingAgentsController
    private

      def parent
        @parent ||= Current.account.agents.find(params[:agent_id])
      end
  end
end
