module Play
  class ApiDocsController < Play::BaseController
    def show
      render layout: false
    end

    def spec
      send_file Rails.root.join("docs/api/openapi.yaml"), type: "text/yaml", disposition: :inline
    end
  end
end
