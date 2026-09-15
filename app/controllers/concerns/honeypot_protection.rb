module HoneypotProtection
  extend ActiveSupport::Concern

  private

  def honeypot_triggered?
    params.dig(controller_name.singularize, :website).present? ||
      params[:website].present?
  end
end
