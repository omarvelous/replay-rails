module Go
  class ListingsController < Go::BaseController
    def show
      @listing = Listing.find_by_param!(params[:id])
      @agents = @listing.agents
    end
  end
end
