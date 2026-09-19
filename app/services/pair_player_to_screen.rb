class PairPlayerToScreen
  Result = Struct.new(:success?, :error, keyword_init: true)

  def initialize(screen:, code:, paired_by: nil)
    @screen = screen
    @code = code&.strip&.upcase
    @paired_by = paired_by
  end

  def call
    player = Player.find_by(pairing_code: @code)
    return Result.new(success?: false, error: "Code not found. Check the TV and try again.") unless player
    return Result.new(success?: false, error: "That code has expired. A new code should appear shortly.") unless player.pairing_code_valid?

    @screen.with_lock do
      @screen.reload_active_player_assignment&.unpair!
      player.reload_active_assignment&.unpair!

      @screen.screen_players.create!(
        player: player,
        paired_by: @paired_by
      )

      player.update!(pairing_code: nil, pairing_code_expires_at: nil)
    end

    player.revoke_all_sessions!

    ActionCable.server.broadcast("pairing_#{@code}", { paired: true })

    Result.new(success?: true)
  end
end
