import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"

export default class extends Controller {
  static values = { apiHost: String }

  async connect() {
    const res = await fetch(`${this.apiHostValue}/players`, {
      method: "POST",
      headers: { "Content-Type": "application/json" }
    })
    const data = await res.json()

    this.token = data.token
    this.element.querySelector("[data-code]").textContent = data.pairing_code

    this.subscription = consumer.subscriptions.create(
      { channel: "PairingChannel", code: data.pairing_code },
      { received: (msg) => { if (msg.paired) this.onPaired() } }
    )

    this.poll = setInterval(() => this.checkStatus(), 3000)
  }

  disconnect() {
    this.subscription?.unsubscribe()
    clearInterval(this.poll)
  }

  async checkStatus() {
    try {
      const res = await fetch(`${this.apiHostValue}/players/${this.token}`)
      if (!res.ok) return
      const data = await res.json()
      if (data.paired) this.onPaired()
    } catch {
      // Network error — keep polling
    }
  }

  onPaired() {
    clearInterval(this.poll)
    this.subscription?.unsubscribe()
    localStorage.setItem("player_token", this.token)
    window.location.href = `/players/${this.token}`
  }
}
