module Api
  class BaseController < ActionController::Base
    protect_from_forgery with: :null_session
    rate_limit to: 60, within: 1.minute, by: -> { request.remote_ip }

    rescue_from ActiveRecord::RecordNotFound do
      render json: { error: "Not found" }, status: :not_found
    end

    rescue_from ActiveRecord::RecordInvalid do |e|
      render json: { error: e.record.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end

    rescue_from ActionController::ParameterMissing do |e|
      render json: { error: e.message }, status: :bad_request
    end

    private

    def authenticate_player!
      @player = Player.find_by(token: params[:player_token] || params[:token])
      render json: { error: "Invalid player token" }, status: :unauthorized unless @player
    end
  end
end
