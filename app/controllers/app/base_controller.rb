module App
  class BaseController < ApplicationController
    include Pundit::Authorization
    layout "app"

    rescue_from Pundit::NotAuthorizedError, with: :handle_unauthorized

    private

      def handle_unauthorized
        redirect_to app_root_path, alert: "You don't have permission to do that."
      end

      def pundit_user
        Current.account_user
      end
  end
end
