class RefreshPairingCode
  Result = Struct.new(:success?, :pairing_code, :expires_at, keyword_init: true)

  def initialize(player:)
    @player = player
  end

  def call
    @player.refresh_pairing_code! unless @player.pairing_code_valid?

    Result.new(
      success?: true,
      pairing_code: @player.pairing_code,
      expires_at: @player.pairing_code_expires_at
    )
  end
end
