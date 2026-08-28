module App
  class QrScansController < App::BaseController
    def index
      @qr_code = authorized_scope(QrCode.all).find(params[:qr_code_id])
      authorize! @qr_code, to: :show?
      @pagy, @scans = pagy(@qr_code.scans.order(created_at: :desc))
    end
  end
end
