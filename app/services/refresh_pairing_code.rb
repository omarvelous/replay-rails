class RefreshPairingCode
  Result = Struct.new(:success?, :pairing_code, :expires_in, keyword_init: true)

  def initialize(player:)
    @player = player
  end

  def call
    if @player.pairing_code_valid?
      expires_in = (@player.pairing_code_expires_at - Time.current).to_i
    else
      @player.refresh_pairing_code!
      expires_in = 600
    end

    Result.new(
      success?: true,
      pairing_code: @player.pairing_code,
      expires_in: expires_in
    )
  end
end
