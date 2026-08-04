module Listings
  class AgentsController < ApplicationController
    before_action :set_listing
    before_action :set_listing_agent, only: %i[ edit update destroy ]

    def new
      @listing_agent = @listing.listing_agents.build(role: "listing_agent")
    end

    def create
      @listing_agent = @listing.listing_agents.build(listing_agent_params)

      if @listing_agent.save
        redirect_to @listing, notice: "Agent was added to the listing."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @listing_agent.update(listing_agent_params)
        redirect_to @listing, notice: "Listing agent was updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @listing_agent.destroy
      redirect_to @listing, notice: "Agent was removed from the listing."
    end

    private

      def current_account
        Current.user.account
      end

      def set_listing
        @listing = current_account.listings.find(params[:listing_id])
      end

      def set_listing_agent
        @listing_agent = @listing.listing_agents.find(params[:id])
      end

      def listing_agent_params
        params.require(:listing_agent).permit(:agent_id, :role)
      end
  end
end
