import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"

export default class extends Controller {
  connect() {
    const token = localStorage.getItem("player_token")
    if (!token) return

    this.subscription = consumer.subscriptions.create(
      { channel: "ScreenChannel", token },
      {
        received: ({ event }) => {
          if (event === "playlist_changed") window.location.reload()
        }
      }
    )

    this.heartbeat = setInterval(() => this.sendHeartbeat(token), 30_000)
    this.sendHeartbeat(token)
  }

  disconnect() {
    this.subscription?.unsubscribe()
    clearInterval(this.heartbeat)
  }

  async sendHeartbeat(token) {
    try {
      await fetch("/heartbeat", {
        method: "POST",
        headers: { "Authorization": `Bearer ${token}` }
      })
    } catch {
      // Network error — will retry next interval
    }
  }
}
