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
          if (event === "content_changed") window.location.reload()
          if (event === "unpaired") this.handleUnpaired()
        },
        rejected: () => {
          this.handleUnpaired()
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
      const res = await fetch(`${this.apiHostValue}/players/${this.playerTokenValue}/heartbeat`, {
        method: "POST"
      })
      if (res.status === 410) this.handleUnpaired()
    } catch {
      // Network error — will retry next interval
    }
  }

  async recordImpression({ adId, position, duration }) {
    try {
      const res = await fetch(`${this.apiHostValue}/players/${this.playerTokenValue}/impressions`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          ad_id: adId,
          playlist_id: this.playlistIdValue,
          position: position,
          duration: duration
        })
      })
      if (res.status === 410) this.handleUnpaired()
    } catch {
      // Network error — impression lost, acceptable
    }
  }

  handleUnpaired() {
    clearInterval(this.heartbeat)
    this.subscription?.unsubscribe()
    // Keep player_token in localStorage — same device, just needs a new pairing code.
    // Only clear token when the Player record itself is deleted (handled by redirect to /players/new
    // which falls back to registerNewPlayer if the token is invalid).
    window.location.href = "/players/new"
  }
}
