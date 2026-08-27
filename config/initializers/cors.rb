Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins /\Ahttps?:\/\/.*\.replay\.(com|localhost)(:\d+)?\z/
    resource "/players/*", headers: :any, methods: [ :get, :post ]
  end
end
