class ScreenChannel < ActionCable::Channel::Base
  def subscribed
    token = params[:token]
    player = Player.find_by(token: token)
    return reject unless player&.paired?

    stream_from "screen_#{player.screen.id}"
  end
end
