class QrCodesController < ApplicationController
  before_action :set_qr_code, only: :show

  def index
    @qr_codes = Current.account.qr_codes
                       .includes(:destination_record)
                       .order(created_at: :desc)
  end

  def show
    @scans = @qr_code.scans.order(created_at: :desc).limit(50)
    @scan_count = @qr_code.scans.count
  end

  private

    def set_qr_code
      @qr_code = Current.account.qr_codes.find(params[:id])
    end
end
