class PairingChannel < ActionCable::Channel::Base
  def subscribed
    code = params[:code]
    stream_from "pairing_#{code}" if code.present?
  end
end
