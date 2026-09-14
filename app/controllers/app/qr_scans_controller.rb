module App
  class QrScansController < App::BaseController
    def index
      @qr_code = authorized_scope(QrCode.all).find_by_param!(params[:qr_code_id])
      authorize! @qr_code, to: :show?
      @pagy, @scans = pagy(@qr_code.scan_events.order(time: :desc))
    end
  end
end
