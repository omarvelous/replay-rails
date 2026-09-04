module ScreenHelper
  def screen_status(screen, active_playlist: nil)
    if !screen.paired?
      :no_player
    elsif screen.online? && active_playlist.present?
      :live
    elsif screen.online?
      :online
    else
      :offline
    end
  end

  def screen_status_badge(status)
    config = {
      no_player: { label: "No player", bg: "bg-gray-50", text: "text-gray-600", ring: "ring-gray-500/10" },
      offline:   { label: "Offline",   bg: "bg-red-50",  text: "text-red-700",  ring: "ring-red-600/10" },
      online:    { label: "Online",    bg: "bg-blue-50", text: "text-blue-700", ring: "ring-blue-700/10" },
      live:      { label: "Live",      bg: "bg-green-50", text: "text-green-700", ring: "ring-green-600/20" }
    }[status]

    tag.span config[:label],
      class: "inline-flex items-center rounded-full #{config[:bg]} px-2 py-0.5 text-xs font-medium #{config[:text]} ring-1 #{config[:ring]} ring-inset"
  end

  def screen_heartbeat_text(screen, status)
    case status
    when :no_player
      "No player assigned"
    when :offline
      if screen.player&.last_heartbeat_at
        "Last seen #{time_ago_in_words(screen.player.last_heartbeat_at)} ago"
      else
        "Never connected"
      end
    when :online, :live
      "Heartbeat #{time_ago_in_words(screen.player.last_heartbeat_at)} ago"
    end
  end

  def screen_heartbeat_icon_color(status)
    {
      no_player: "text-gray-300",
      offline:   "text-red-400",
      online:    "text-blue-400",
      live:      "text-green-500"
    }[status]
  end
end
