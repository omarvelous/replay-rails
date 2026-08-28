module Admin
  class VersionsController < Admin::ApplicationController
    def resource_class
      PaperTrail::Version
    end
  end
end
