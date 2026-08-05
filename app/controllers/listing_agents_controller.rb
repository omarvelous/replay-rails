class ListingAgentsController < ApplicationController
  before_action :set_listing_agent, only: %i[ edit update destroy ]

  def index
    @listing_agents = parent.listing_agents.includes(:listing, :agent)
  end

  def new
    @listing_agent = parent.listing_agents.build(role: "listing_agent")
  end

  def create
    @listing_agent = parent.listing_agents.build(listing_agent_params)

    if @listing_agent.save
      respond_to do |format|
        format.turbo_stream { flash.now[:notice] = t(".success") }
        format.html { redirect_to parent, notice: t(".success") }
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
        format.turbo_stream { flash.now[:notice] = t(".success") }
        format.html { redirect_to parent, notice: t(".success") }
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @listing_agent.destroy
    respond_to do |format|
      format.turbo_stream { flash.now[:notice] = t(".success") }
      format.html { redirect_to parent, notice: t(".success") }
    end
  end

  private

    def parent
      raise NotImplementedError
    end
    helper_method :parent

    def set_listing_agent
      @listing_agent = Current.account.listing_agents.find(params[:id])
    end

    def listing_agent_params
      params.require(:listing_agent).permit(:listing_id, :agent_id, :role)
    end
end
