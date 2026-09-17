Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins /\Ahttps?:\/\/.*\.(replaytv\.co|replaytv\.dev|replay\.localhost)(:\d+)?\z/
    resource "/v1/players", headers: :any, methods: [ :post ], credentials: true
    resource "/v1/player", headers: :any, methods: [ :get ], credentials: true
    resource "/v1/player/*", headers: :any, methods: [ :get, :post ], credentials: true, expose: [ "ETag" ]
  end
end
