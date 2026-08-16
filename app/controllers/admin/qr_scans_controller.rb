module Admin
  class QrScansController < BaseController
    def index
      @qr_scans = QrScan.includes(:qr_code, :account, :ad, :screen).order(created_at: :desc).limit(100)
    end

    def show
      @qr_scan = QrScan.find(params[:id])
    end
  end
end
