class ScansController < ApplicationController
  skip_before_action :require_authentication

  def show
    qr = QrCode.find_by!(token: params[:token], active: true)

    scan = qr.scans.create!(
      account: qr.account,
      ad_id: params[:a],
      screen_id: params[:s],
      context: scan_context,
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    )

    if qr.destination_url.present?
      destination = URI.parse(qr.destination_url).to_s
    elsif qr.destination_record.present?
      destination = polymorphic_url([ :go, qr.destination_record ], subdomain: "", scan_id: scan.id)
    else
      destination = app_root_path
    end

    Ahoy::Tracker.new(request: request).track "qr.scanned",
      qr_code_id: qr.id,
      destination_url: destination,
      screen_content_id: params[:sc].presence&.to_i,
      ad_id: params[:a].presence&.to_i,
      screen_id: params[:s].presence&.to_i
    redirect_to destination, allow_other_host: true
  end

  private

    def scan_context
      ctx = {}
      ctx[:playlist_id] = params[:p].to_i if params[:p].present?
      ctx
    end
end
