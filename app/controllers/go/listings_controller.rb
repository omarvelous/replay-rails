module Go
  class ListingsController < ApplicationController
    skip_before_action :require_authentication
    layout "public"

    def show
      @listing = Listing.find(params[:id])
      @agents = @listing.agents
    end
  end
end
