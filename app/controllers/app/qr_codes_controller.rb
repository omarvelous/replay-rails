module App
  class QrCodesController < BaseController
  before_action :set_qr_code, only: :show

  def index
    @qr_codes = authorized_scope(QrCode.all)
                       .includes(:destination_record)
                       .order(created_at: :desc)
  end

  def show
    authorize! @qr_code
    @scans = @qr_code.scans.order(created_at: :desc).limit(50)
    @scan_count = @qr_code.scans.count
  end

  private

    def set_qr_code
      @qr_code = Current.account.qr_codes.find(params[:id])
    end
  end
end
