module Docs
  class PagesController < ApplicationController
    skip_before_action :require_authentication
    layout "docs"

    def index
      @categories = Docs::Manifest.categories
    end

    def show
      @page = Docs::Manifest.find(params[:slug])
      raise ActionController::RoutingError, "Not Found" unless @page

      render template: "docs/pages/#{@page[:template]}"
    end
  end
end
