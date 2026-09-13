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
      qr_code_id: qr.id,
      destination_url: destination,
      screen_content_id: params[:sc].presence&.to_i,
      ad_id: params[:a].presence&.to_i,
      screen_id: params[:s].presence&.to_i,
      request: request
    )
    redirect_to destination, allow_other_host: true
  end
end
