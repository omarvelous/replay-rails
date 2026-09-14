module Go
  class ListingsController < ApplicationController
    skip_before_action :require_authentication
    layout "public"

    def show
      @listing = Listing.find_by_param!(params[:id])
      @agents = @listing.agents
    end
  end
end
