module Go
  class ExperiencesController < ApplicationController
    skip_before_action :require_authentication
    layout "player"

    def show
      @experience = Experience.find_by_param!(params[:id])
      @listing = @experience.listing
      @agent = @experience.default_agent
      render "play/players/experience"
    end
  end
end
