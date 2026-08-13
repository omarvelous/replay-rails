class ScansController < ApplicationController
  skip_before_action :require_authentication

  def show
    qr = QrCode.find_by!(token: params[:token], active: true)

    qr.scans.create!(
      account: qr.account,
      source_type: source_type,
      source_id: source_id,
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    )

    if qr.destination_url.present?
      redirect_to qr.destination_url, allow_other_host: true
    elsif qr.destination_record.present?
      redirect_to polymorphic_path([ :go, qr.destination_record ])
    else
      redirect_to root_path
    end
  end

  private

    def source_type
      params[:src]&.split(".")&.first
    end

    def source_id
      params[:src]&.split(".")&.last&.to_i
    end
end
