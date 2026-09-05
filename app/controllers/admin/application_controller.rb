module Admin
  class ApplicationController < Administrate::ApplicationController
    include Authentication
    before_action :require_admin!
    before_action :strip_subdomain_param

    around_action :without_tenant

    private

      def strip_subdomain_param
        params.delete(:subdomain)
      end

      def require_admin!
        unless Current.user&.admin?
          redirect_to app_root_url(subdomain: "app"), alert: "Not authorized.", allow_other_host: true
        end
      end

      def without_tenant(&block)
        ActsAsTenant.without_tenant(&block)
      end
  end
end
