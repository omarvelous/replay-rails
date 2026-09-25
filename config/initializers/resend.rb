if Rails.env.production? || Rails.env.staging?
  Resend.api_key = Rails.application.credentials.dig(:resend, :api_key)
end
