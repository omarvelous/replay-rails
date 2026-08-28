module App
  class QrCodesController < BaseController
  before_action :set_qr_code, only: :show

  def index
    base = authorized_scope(QrCode.all)
             .includes(:destination_record)
             .order(created_at: :desc)
    @pagy, @qr_codes = pagy(base)
  end

  def show
    authorize! @qr_code
    @scans = @qr_code.scans.order(created_at: :desc).limit(5)
    @scan_count = @qr_code.scans.count
  end

  private

    def set_qr_code
      @qr_code = Current.account.qr_codes.find(params[:id])
    end
  end
end
