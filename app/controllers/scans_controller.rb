class ScansController < ApplicationController
  skip_before_action :require_authentication

  def show
    qr = QrCode.find_by!(token: params[:token], active: true)

    if qr.destination_url.present?
      destination = URI.parse(qr.destination_url).to_s
    elsif qr.destination_record.present?
      destination = polymorphic_url([ :go, qr.destination_record ], subdomain: "")
    else
      destination = app_root_path
    end

    Analytics::Events::QrScanned.create(
      qr_code_pid: qr.public_id,
      destination_url: destination,
      screen_content_pid: params[:sc].presence,
      ad_pid: params[:a].presence,
      screen_pid: params[:s].presence,
      request: request
    )
    redirect_to destination, allow_other_host: true
  end
end
