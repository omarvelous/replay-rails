Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins /\Ahttps?:\/\/.*\.(replaytv\.co|replaytv\.dev|replay\.localhost)(:\d+)?\z/
    resource "/players/*", headers: :any, methods: [ :get, :post ]
  end
end
