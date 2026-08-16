module Admin
  class BaseController < ApplicationController
    before_action :require_admin!

    layout "admin"

    private

      def require_admin!
        unless Current.user&.admin?
          redirect_to app_root_url(subdomain: "app"), alert: "Not authorized.", allow_other_host: true
        end
      end
  end
end
