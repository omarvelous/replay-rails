module Go
  class AgentsController < ApplicationController
    skip_before_action :require_authentication
    layout "public"

    def show
      @agent = Agent.find(params[:id])
      @listings = @agent.listings.where(status: "active").limit(6)
    end
  end
end
