class AgentsController < ApplicationController
  before_action :set_agent, only: %i[ show edit update destroy listings ]

  def index
    @agents = Current.account.agents.order(:name)
  end

  def show
  end

  def new
    @agent = Current.account.agents.build
  end

  def create
    @agent = Current.account.agents.build(agent_params)

    if @agent.save
      respond_to do |format|
        format.turbo_stream { flash.now[:notice] = t(".success") }
        format.html { redirect_to @agent, notice: t(".success") }
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @agent.update(agent_params)
      respond_to do |format|
        format.turbo_stream { flash.now[:notice] = t(".success") }
        format.html { redirect_to @agent, notice: t(".success") }
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @agent.destroy
    redirect_to agents_path, notice: t(".success")
  end

  def listings
    @listings = @agent.listings.distinct
  end

  private

    def set_agent
      @agent = Current.account.agents.find(params[:id])
    end

    def agent_params
      params.require(:agent).permit(:name, :email, :phone, :user_id)
    end
end
