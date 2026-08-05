class AgentsController < ApplicationController
  before_action :set_agent, only: %i[ show edit update destroy ]

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
      redirect_to @agent, notice: t(".success")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @agent.update(agent_params)
      redirect_to @agent, notice: t(".success")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @agent.destroy
    redirect_to agents_path, notice: t(".success")
  end

  private

    def set_agent
      @agent = Current.account.agents.find(params[:id])
    end

    def agent_params
      params.require(:agent).permit(:name, :email, :phone, :user_id)
    end
end
