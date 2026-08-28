module Admin
  class VersionsController < Admin::ApplicationController
    def index
      base = PaperTrail::Version.order(created_at: :desc)
      base = base.where(item_type: params[:item_type]) if params[:item_type].present?
      base = base.where(event: params[:event]) if params[:event].present?
      base = base.where(account_id: params[:account_id]) if params[:account_id].present?
      @pagy, @versions = pagy(base, limit: 50)
    end
  end
end
