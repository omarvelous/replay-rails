import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["toggle"]

  connect() {
    const frame = this.element.querySelector("turbo-frame#drawer")
    if (!frame) return

    this.observer = new MutationObserver(() => {
      if (frame.children.length > 0) {
        this.open()
      } else {
        this.close()
      }
    })
    this.observer.observe(frame, { childList: true })

    // Clear frame content when drawer closes via overlay click
    this.toggleTarget.addEventListener("change", () => {
      if (!this.toggleTarget.checked && frame.children.length > 0) {
        frame.innerHTML = ""
      }
    })
  }

  disconnect() {
    this.observer?.disconnect()
  }

  open() {
    this.toggleTarget.checked = true
  }

  close() {
    this.toggleTarget.checked = false
    const frame = this.element.querySelector("turbo-frame#drawer")
    if (frame) frame.innerHTML = ""
  }
}
