import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"
import Analytics from "analytics"

export default class extends Controller {
  static values = {
    apiHost: String,
    playerToken: String,
    playlistId: Number,
    screenId: Number,
    screenContentId: Number
  }

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

    // Track device connected
    if (this.hasScreenIdValue) {
      Analytics.create("device.connected", {
        screen_id: this.screenIdValue,
        player_token: this.playerTokenValue
      })
    }
  }

  disconnect() {
    this.subscription?.unsubscribe()
    clearInterval(this.heartbeat)
  }

  async sendHeartbeat() {
    try {
      const res = await fetch(`${this.apiHostValue}/players/${this.playerTokenValue}/heartbeat`, {
        method: "POST",
        credentials: "include"
      })
      if (res.status === 410) this.handleUnpaired()
    } catch {
      // Network error — will retry next interval
    }
  }

  recordImpression({ adId, position, duration }) {
    Analytics.create("content.impressed", {
      ad_id: adId,
      screen_id: this.screenIdValue,
      screen_content_id: this.screenContentIdValue,
      playlist_id: this.playlistIdValue,
      position: position,
      duration: duration
    })
  }

  handleUnpaired() {
    clearInterval(this.heartbeat)
    this.subscription?.unsubscribe()
    window.location.href = "/players/new"
  }
}
