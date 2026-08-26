module QrHelper
  def qr_svg(qr_code, ad: nil, screen: nil)
    url = qr_scan_url(token: qr_code.token)
    query = {}
    query[:a] = ad.id if ad
    query[:s] = screen.id if screen
    url += "?#{query.to_query}" if query.any?

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
