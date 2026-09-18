class ScreenChannel < ActionCable::Channel::Base
  def subscribed
    player = current_player
    return reject unless player&.paired?

    stream_from "screen_#{player.screen.id}"
  end
end
