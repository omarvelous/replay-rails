module Go
  class AgentsController < Go::BaseController
    def show
      @agent = Agent.find_by_param!(params[:id])
      @listings = @agent.listings.where(status: "active").limit(6)
    end
  end
end
