module QrHelper
  def qr_svg(qr_code, ad: nil, screen: nil)
    url = qr_scan_url(token: qr_code.token)
    query = {}
    query[:a] = ad.id if ad
    query[:s] = screen.id if screen
    url += "?#{query.to_query}" if query.any?

    qr = RQRCode::QRCode.new(url)
    svg = qr.as_svg(
      offset: 0,
      color: "000",
      shape_rendering: "crispEdges",
      module_size: 4,
      standalone: true,
      use_path: true
    )

    # Replace fixed width/height with 100% so the SVG scales to fill its container
    svg = svg.sub(/width="[^"]*"/, 'width="100%"')
    svg = svg.sub(/height="[^"]*"/, 'height="100%"')
    svg.html_safe
  end
end
