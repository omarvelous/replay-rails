import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"

export default class extends Controller {
  static values = { apiHost: String, playerToken: String, playlistId: Number }

  connect() {
    const token = this.playerTokenValue
    if (!token) return

    this.subscription = consumer.subscriptions.create(
      { channel: "ScreenChannel", token },
      {
        received: ({ event }) => {
          if (event === "playlist_changed") window.location.reload()
        }
      }
    )

    this.heartbeat = setInterval(() => this.sendHeartbeat(), 30_000)
    this.sendHeartbeat()

    this.element.addEventListener("slideshow:impression", (e) => {
      this.recordImpression(e.detail)
    })
  }

  disconnect() {
    this.subscription?.unsubscribe()
    clearInterval(this.heartbeat)
  }

  async sendHeartbeat() {
    try {
      await fetch(`${this.apiHostValue}/players/${this.playerTokenValue}/heartbeat`, {
        method: "POST"
      })
    } catch {
      // Network error — will retry next interval
    }
  }

  async recordImpression({ adId, position, duration }) {
    try {
      await fetch(`${this.apiHostValue}/players/${this.playerTokenValue}/impressions`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          ad_id: adId,
          playlist_id: this.playlistIdValue,
          position: position,
          duration: duration
        })
      })
    } catch {
      // Network error — impression lost, acceptable
    }
  }
}
