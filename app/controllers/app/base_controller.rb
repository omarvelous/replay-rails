module App
  class BaseController < ApplicationController
    include ActionPolicy::Controller
    layout "app"

    authorize :user, through: :current_user
    authorize :account, through: :current_account

    rescue_from ActionPolicy::Unauthorized, with: :handle_unauthorized

    before_action :set_paper_trail_whodunnit

    private

      def current_user
        Current.user
      end

      def current_account
        Current.account
      end

      def handle_unauthorized
        redirect_to app_root_path, alert: "You don't have permission to do that."
      end

      def user_for_paper_trail
        Current.user&.id
      end
  end
end
