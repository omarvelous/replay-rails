module QrHelper
  def qr_svg(qr_code, source: nil)
    url = qr_scan_url(token: qr_code.token)
    url += "?src=#{source}" if source.present?
    qr = RQRCode::QRCode.new(url)
    qr.as_svg(
      offset: 0,
      color: "000",
      shape_rendering: "crispEdges",
      module_size: 4,
      standalone: true,
      use_path: true
    ).html_safe
  end
end
