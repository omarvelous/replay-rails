module Admin
  class ApplicationController < Administrate::ApplicationController
    include Authentication
    before_action :require_admin!
    before_action :strip_subdomain_param

    around_action :without_tenant

    private

      def find_resource(param)
        resource_class = resource_resolver.resource_class
        if resource_class.respond_to?(:find_by_param!)
          scoped_resource.find_by_param!(param)
        else
          scoped_resource.find(param)
        end
      end

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
