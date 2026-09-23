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

    def api
      render layout: false
    end

    def openapi_spec
      send_file Rails.root.join("docs/api/openapi.yaml"), type: "text/yaml", disposition: :inline
    end
  end
end
