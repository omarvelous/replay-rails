module QrHelper
  def qr_scan_full_url(qr_code)
    if ENV["QR_SHORT_DOMAIN"].present?
      qr_scan_url(token: qr_code.token, host: ENV["QR_SHORT_DOMAIN"], port: nil, protocol: "https")
    else
      qr_scan_url(token: qr_code.token)
    end
  end

  def qr_svg(qr_code)
    url = qr_scan_full_url(qr_code)

    qr = RQRCode::QRCode.new(url)
    svg = qr.as_svg(
      offset: 0,
      color: "000",
      shape_rendering: "crispEdges",
      module_size: 4,
      standalone: true,
      use_path: true
    )

    # Extract original dimensions to build a viewBox, then scale to 100%
    size = qr.modules.length * 4 # module_count * module_size
    svg = svg.sub("<svg ", "<svg viewBox=\"0 0 #{size} #{size}\" ")
    svg = svg.sub(/width="[^"]*"/, 'width="100%"')
    svg = svg.sub(/height="[^"]*"/, 'height="100%"')
    svg.html_safe
  end
end
