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
      redirect_to qr.destination_url, allow_other_host: true
    elsif qr.destination_record.present?
      redirect_to polymorphic_url([ :go, qr.destination_record ], subdomain: "", scan_id: scan.id),
                  allow_other_host: true
    else
      redirect_to app_root_path
    end
  end

  private

    def scan_context
      ctx = {}
      ctx[:playlist_id] = params[:p].to_i if params[:p].present?
      ctx
    end
end
