module Admin
  class QrCodesController < BaseController
    def index
      @qr_codes = QrCode.includes(:account, :destination_record).order(created_at: :desc)
    end

    def show
      @qr_code = QrCode.find(params[:id])
    end
  end
end
