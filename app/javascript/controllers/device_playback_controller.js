import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"
import Analytics from "analytics"

export default class extends Controller {
  static values = {
    apiHost: String,
    playerToken: String,
    playlistId: Number,
    screenId: Number,
    screenContentId: Number,
    accountId: Number
  }

  connect() {
    const token = this.playerTokenValue
    if (!token) return

    this.subscription = consumer.subscriptions.create(
      { channel: "ScreenChannel", token },
      {
        received: ({ event }) => {
          if (event === "content_changed" || event === "content_nudge") {
            clearTimeout(this.nudgeTimeout)
            this.nudgeTimeout = setTimeout(() => this.checkManifest(), 2000)
          }
          if (event === "unpaired") this.handleUnpaired()
        },
        rejected: () => {
          this.handleUnpaired()
        }
      }
    )

    this.heartbeat = setInterval(() => this.sendHeartbeat(), 30_000)
    this.sendHeartbeat()

    // Manifest polling for content change detection
    this.manifestETag = null
    this.manifestUrl = `${this.apiHostValue}/players/${this.playerTokenValue}/manifest`
    this.manifestInterval = setInterval(() => this.checkManifest(), 30_000)

    this.element.addEventListener("slideshow:impression", (e) => {
      this.recordImpression(e.detail)
    })

    // Track device connected
    if (this.hasScreenIdValue) {
      Analytics.create("device.connected", {
        screen_id: this.screenIdValue,
        player_token: this.playerTokenValue,
        account_id: this.accountIdValue
      })
    }
  }

  disconnect() {
    this.subscription?.unsubscribe()
    clearInterval(this.heartbeat)
    clearInterval(this.manifestInterval)
    clearTimeout(this.nudgeTimeout)
  }

  async checkManifest() {
    try {
      const options = { credentials: "include" }
      if (this.manifestETag) {
        options.headers = { "If-None-Match": this.manifestETag }
      }

      const res = await fetch(this.manifestUrl, options)

      if (res.status === 200) {
        const newETag = res.headers.get("ETag")
        if (this.manifestETag && newETag !== this.manifestETag) {
          // Content changed — reload
          window.location.reload()
        }
        this.manifestETag = newETag
      }
      // 304 = unchanged, do nothing
    } catch {
      // Network error — will retry next interval
    }
  }

  async sendHeartbeat() {
    try {
      const res = await fetch(`${this.apiHostValue}/players/${this.playerTokenValue}/heartbeat`, {
        method: "POST",
        credentials: "include",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          screen_width: screen.width,
          screen_height: screen.height
        })
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
      duration: duration,
      account_id: this.accountIdValue
    })
  }

  handleUnpaired() {
    clearInterval(this.heartbeat)
    this.subscription?.unsubscribe()
    window.location.href = "/players/new"
  }
}
