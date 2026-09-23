if ENV["OPENAPI"]
  require "rspec/openapi"

  RSpec::OpenAPI.path = Rails.root.join("docs/api/openapi.yaml").to_s
  RSpec::OpenAPI.title = "RePlay Player API"
  RSpec::OpenAPI.servers = [
    { url: "https://play.replaytv.co", description: "Production" },
    { url: "http://play.replay.localhost:3000", description: "Development" }
  ]
  RSpec::OpenAPI.request_headers = %w[Authorization]
  RSpec::OpenAPI.response_headers = %w[ETag]
end
