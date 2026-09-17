import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"
import QrCreator from "qr-creator"

export default class extends Controller {
  static values = { apiHost: String, pairHost: String }

  async connect() {
    const publicId = localStorage.getItem("player_public_id")

    if (publicId) {
      const alreadyPaired = await this.checkIfPaired()
      if (alreadyPaired) return

      await this.refreshPairingCode()
    } else {
      await this.registerNewPlayer()
    }

    this.subscribeToPairing()
    this.pollDelay = 3000
    this.schedulePoll()
    this.startCountdown()
  }

  disconnect() {
    this.subscription?.unsubscribe()
    clearTimeout(this.pollTimeout)
    clearInterval(this.countdownInterval)
  }

  async registerNewPlayer() {
    const res = await fetch(`${this.apiHostValue}/v1/players`, {
      method: "POST",
      credentials: "include",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        screen_width: screen.width,
        screen_height: screen.height,
        touch_capable: navigator.maxTouchPoints > 0,
        app_version: window.REPLAY_APP_VERSION || null
      })
    })
    const { data } = await res.json()

    this.publicId = data.public_id
    this.sessionId = data.session_id
    this.pairingCode = data.pairing_code
    this.expiresIn = data.expires_in
    localStorage.setItem("player_public_id", this.publicId)

    // Set cookie via same-origin Play endpoint (cross-origin API can't set SameSite=Lax cookies)
    await fetch("/player/session", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ session_id: this.sessionId })
    })

    this.displayCode(data.pairing_code)
  }

  async checkIfPaired() {
    try {
      const res = await fetch(`${this.apiHostValue}/v1/player`, { credentials: "include" })
      if (!res.ok) return false
      const { data } = await res.json()
      if (data.paired) {
        this.publicId = localStorage.getItem("player_public_id")
        window.location.replace("/player")
        return true
      }
    } catch {
      // Network error — fall through to pairing
    }
    return false
  }

  async refreshPairingCode() {
    const res = await fetch(`${this.apiHostValue}/v1/player/pairing_code`, {
      method: "POST",
      credentials: "include",
      headers: { "Content-Type": "application/json" }
    })

    if (res.ok) {
      const { data } = await res.json()
      this.publicId = localStorage.getItem("player_public_id")
      this.pairingCode = data.pairing_code
      this.expiresIn = data.expires_in
      this.displayCode(data.pairing_code)
    } else {
      localStorage.removeItem("player_public_id")
      await this.registerNewPlayer()
    }
  }

  subscribeToPairing() {
    this.subscription?.unsubscribe()
    this.subscription = consumer.subscriptions.create(
      { channel: "PairingChannel", code: this.pairingCode },
      { received: (msg) => { if (msg.paired) this.onPaired(msg.session_id) } }
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

    await this.refreshPairingCode()
    this.subscribeToPairing()
    this.startCountdown()
  }

  schedulePoll() {
    this.pollTimeout = setTimeout(() => this.checkStatus(), this.pollDelay)
  }

  async checkStatus() {
    try {
      const res = await fetch(`${this.apiHostValue}/v1/player`, { credentials: "include" })
      if (!res.ok) {
        this.backoff()
        return
      }
      const { data } = await res.json()
      if (data.paired) return this.onPaired(this.sessionId)
      this.pollDelay = 3000 // reset on success
    } catch {
      this.backoff()
    }
    this.schedulePoll()
  }

  backoff() {
    this.pollDelay = Math.min(this.pollDelay * 2, 60000)
  }

  async onPaired(sessionId) {
    clearTimeout(this.pollTimeout)
    clearInterval(this.countdownInterval)
    this.subscription?.unsubscribe()

    // Set cookie with the new session (pairing revokes old sessions and creates a new one)
    if (sessionId) {
      await fetch("/player/session", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ session_id: sessionId })
      })
    }

    window.location.href = "/player"
  }
}
