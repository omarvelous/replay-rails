module PairingHelpers
  def pair_player!(screen, player, paired_by: nil)
    screen.with_lock do
      screen.reload_active_player_assignment&.unpair!
      player.reload_active_assignment&.unpair!

      screen.screen_players.create!(
        player: player,
        paired_by: paired_by
      )

      player.update!(pairing_code: nil, pairing_code_expires_at: nil)
    end
  end
end

RSpec.configure do |config|
  config.include PairingHelpers
end
