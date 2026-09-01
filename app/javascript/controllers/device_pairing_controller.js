import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"
import QrCreator from "qr-creator"

export default class extends Controller {
  static values = { apiHost: String, pairHost: String }

  async connect() {
    const existingToken = localStorage.getItem("player_token")

    if (existingToken) {
      const alreadyPaired = await this.checkIfPaired(existingToken)
      if (alreadyPaired) return

      await this.refreshPairingCode(existingToken)
    } else {
      await this.registerNewPlayer()
    }

    this.subscribeToPairing()
    this.poll = setInterval(() => this.checkStatus(), 3000)
    this.startCountdown()
  }

  disconnect() {
    this.subscription?.unsubscribe()
    clearInterval(this.poll)
    clearInterval(this.countdownInterval)
  }

  async registerNewPlayer() {
    const res = await fetch(`${this.apiHostValue}/players`, {
      method: "POST",
      headers: { "Content-Type": "application/json" }
    })
    const data = await res.json()

    this.token = data.token
    this.pairingCode = data.pairing_code
    this.expiresIn = data.expires_in
    localStorage.setItem("player_token", this.token)
    this.displayCode(data.pairing_code)
  }

  async checkIfPaired(token) {
    try {
      const res = await fetch(`${this.apiHostValue}/players/${token}`)
      if (!res.ok) return false
      const data = await res.json()
      if (data.paired) {
        this.token = token
        window.location.replace(`/players/${token}`)
        return true
      }
    } catch {
      // Network error — fall through to pairing
    }
    return false
  }

  async refreshPairingCode(token) {
    const res = await fetch(`${this.apiHostValue}/players/${token}/pairing_code`, {
      method: "POST",
      headers: { "Content-Type": "application/json" }
    })

    if (res.ok) {
      const data = await res.json()
      this.token = token
      this.pairingCode = data.pairing_code
      this.expiresIn = data.expires_in
      this.displayCode(data.pairing_code)
    } else {
      localStorage.removeItem("player_token")
      await this.registerNewPlayer()
    }
  }

  subscribeToPairing() {
    this.subscription?.unsubscribe()
    this.subscription = consumer.subscriptions.create(
      { channel: "PairingChannel", code: this.pairingCode },
      { received: (msg) => { if (msg.paired) this.onPaired() } }
    )
  }

  displayCode(code) {
    this.element.querySelector("[data-code]").textContent = code

    const qrContainer = this.element.querySelector("[data-qr]")
    if (qrContainer) {
      qrContainer.innerHTML = ""
      const pairUrl = `${this.pairHostValue}/pair?code=${code}`
      QrCreator.render({
        text: pairUrl,
        radius: 0,
        ecLevel: "M",
        fill: "#000",
        background: "#fff",
        size: 140,
        quiet: 2
      }, qrContainer)
    }
  }

  startCountdown() {
    this.secondsRemaining = this.expiresIn || 600
    this.updateCountdownDisplay()

    this.countdownInterval = setInterval(() => {
      this.secondsRemaining -= 1

      if (this.secondsRemaining <= 0) {
        this.onCodeExpired()
      } else {
        this.updateCountdownDisplay()
      }
    }, 1000)
  }

  updateCountdownDisplay() {
    const el = this.element.querySelector("[data-countdown]")
    if (!el) return

    const minutes = Math.floor(this.secondsRemaining / 60)
    const seconds = this.secondsRemaining % 60
    el.textContent = `${minutes}:${seconds.toString().padStart(2, "0")}`
  }

  async onCodeExpired() {
    clearInterval(this.countdownInterval)

    // Refresh the code using the existing token
    await this.refreshPairingCode(this.token)
    this.subscribeToPairing()
    this.startCountdown()
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
    clearInterval(this.countdownInterval)
    this.subscription?.unsubscribe()
    localStorage.setItem("player_token", this.token)
    window.location.href = `/players/${this.token}`
  }
}
