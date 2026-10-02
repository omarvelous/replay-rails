class PlayerSession < ApplicationRecord
  belongs_to :player

  scope :active, -> { where(revoked_at: nil) }

  def revoke!
    update!(revoked_at: Time.current)
  end

  def bearer_token
    Rails.application.message_verifier(:player_session).generate(id)
  end
end
