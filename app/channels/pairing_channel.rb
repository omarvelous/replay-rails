class PairingChannel < ActionCable::Channel::Base
  def subscribed
    player = Player.find_by(pairing_code: params[:code])

    if player&.pairing_code_valid?
      stream_from "pairing_#{params[:code]}"
    else
      reject
    end
  end
end
