class ListingAgentsController < ApplicationController
  before_action :set_listing_agent, only: %i[ edit update destroy ]

  def index
    raise ActiveRecord::RecordNotFound unless scope
    @listing_agents = scope.includes(:listing, :agent)
  end

  def new
    @listing_agent = ListingAgent.new(
      listing_id: current_listing&.id,
      agent_id: current_agent&.id,
      role: "listing_agent"
    )
  end

  def create
    @listing_agent = ListingAgent.new(listing_agent_params)

    if @listing_agent.save
      respond_to do |format|
        format.turbo_stream do
          flash.now[:notice] = "Agent and listing linked."
          @listing_agents = scope.includes(:listing, :agent)
        end
        format.html { redirect_to redirect_target, notice: "Agent and listing linked." }
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
          @listing_agents = scope.includes(:listing, :agent)
          render "listing_agents/create"
        end
        format.html { redirect_to redirect_target, notice: "Listing agent was updated." }
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @listing_agent.destroy
    respond_to do |format|
      format.turbo_stream do
        flash.now[:notice] = "Agent and listing unlinked."
        @listing_agents = scope.includes(:listing, :agent)
        render "listing_agents/create"
      end
      format.html { redirect_to redirect_target, notice: "Agent and listing unlinked." }
    end
  end

  private

    def current_account
      Current.user.account
    end

    def current_listing
      @current_listing ||= current_account.listings.find_by(id: params[:listing_id])
    end
    helper_method :current_listing

    def current_agent
      @current_agent ||= current_account.agents.find_by(id: params[:agent_id])
    end
    helper_method :current_agent

    def scope
      if current_listing
        current_listing.listing_agents
      elsif current_agent
        current_agent.listing_agents
      end
    end

    def set_listing_agent
      @listing_agent = ListingAgent.joins(:listing).find_by!(
        id: params[:id],
        listings: { account_id: current_account.id }
      )
      @current_listing = @listing_agent.listing
      @current_agent = @listing_agent.agent
    end

    def redirect_target
      current_listing || current_agent || @listing_agent&.listing
    end

    def listing_agent_params
      params.require(:listing_agent).permit(:listing_id, :agent_id, :role)
    end
end
