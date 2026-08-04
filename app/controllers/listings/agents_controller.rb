module Listings
  class AgentsController < ApplicationController
    before_action :set_listing
    before_action :set_listing_agent, only: %i[ edit update destroy ]

    def index
      @listing_agents = @listing.listing_agents.includes(:agent)
    end

    def new
      @listing_agent = @listing.listing_agents.build(role: "listing_agent")
    end

    def create
      @listing_agent = @listing.listing_agents.build(listing_agent_params)

      if @listing_agent.save
        respond_to do |format|
          format.turbo_stream { flash.now[:notice] = "Agent was added to the listing." }
          format.html { redirect_to @listing, notice: "Agent was added to the listing." }
        end
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @listing_agent.update(listing_agent_params)
        respond_to do |format|
          format.turbo_stream do
            flash.now[:notice] = "Listing agent was updated."
            render "listings/agents/create"
          end
          format.html { redirect_to @listing, notice: "Listing agent was updated." }
        end
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @listing_agent.destroy
      respond_to do |format|
        format.turbo_stream do
          flash.now[:notice] = "Agent was removed from the listing."
          render "listings/agents/create"
        end
        format.html { redirect_to @listing, notice: "Agent was removed from the listing." }
      end
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
