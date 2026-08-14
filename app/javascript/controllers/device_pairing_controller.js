import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"

export default class extends Controller {
  static values = { code: String, token: String }

  connect() {
    this.subscription = consumer.subscriptions.create(
      { channel: "PairingChannel", code: this.codeValue },
      { received: (data) => { if (data.paired) this.onPaired(data.token) } }
    )
    this.poll = setInterval(() => this.checkStatus(), 3000)
  }

  disconnect() {
    this.subscription?.unsubscribe()
    clearInterval(this.poll)
  }

  async checkStatus() {
    try {
      const res = await fetch(`/player/status?code=${this.codeValue}`)
      if (!res.ok) return
      const data = await res.json()
      if (data.paired) this.onPaired(data.token)
    } catch {
      // Network error — keep polling
    }
  }

  onPaired(token) {
    clearInterval(this.poll)
    this.subscription?.unsubscribe()
    localStorage.setItem("player_token", token)
    window.location.href = "/player/play"
  }
}
