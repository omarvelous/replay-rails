module Api
  class BaseController < ActionController::Base
    include PlayerAuthentication

    skip_forgery_protection
    rate_limit to: 60, within: 1.minute, by: -> { request.remote_ip }

    rescue_from ActiveRecord::RecordNotFound do
      render_error "Not found", status: :not_found
    end

    rescue_from ActiveRecord::RecordInvalid do |e|
      render_error e.record.errors.full_messages.to_sentence, status: :unprocessable_entity
    end

    rescue_from ActionController::ParameterMissing do |e|
      render_error e.message, status: :bad_request
    end

    private

    def request_player_authentication
      render_error "Invalid session", status: :unauthorized
    end

    def render_data(data = nil, status: :ok, **kwargs)
      render json: { data: data || kwargs }, status: status
    end

    def render_error(message, status: :unprocessable_entity)
      render json: { error: { message: message } }, status: status
    end
  end
end
