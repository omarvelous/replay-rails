module Agents
  class ListingsController < ApplicationController
    before_action :set_agent
    before_action :set_listing_agent, only: %i[ destroy ]

    def index
      @listing_agents = @agent.listing_agents.includes(:listing)
    end

    def destroy
      @listing_agent.destroy
      respond_to do |format|
        format.turbo_stream do
          flash.now[:notice] = "Listing was removed from the agent."
        end
        format.html { redirect_to @agent, notice: "Listing was removed from the agent." }
      end
    end

    private

      def current_account
        Current.user.account
      end

      def set_agent
        @agent = current_account.agents.find(params[:agent_id])
      end

      def set_listing_agent
        @listing_agent = @agent.listing_agents.find(params[:id])
      end
  end
end
