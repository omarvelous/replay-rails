module Go
  class ExperiencesController < Go::BaseController
    def show
      @experience = Experience.find_by_param!(params[:id])
      @listing = @experience.listing
      @agent = @experience.default_agent
    end
  end
end
