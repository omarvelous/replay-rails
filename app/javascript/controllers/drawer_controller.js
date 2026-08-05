import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog"]

  dialogTargetConnected() {
    const frame = this.dialogTarget.querySelector("turbo-frame#drawer")
    if (!frame) return

    this.observer = new MutationObserver(() => {
      if (frame.children.length > 0) {
        this.open()
      }
    })
    this.observer.observe(frame, { childList: true })

    this.dialogTarget.addEventListener("close", () => {
      if (frame) frame.innerHTML = ""
    })
  }

  disconnect() {
    this.observer?.disconnect()
  }

  open() {
    this.dialogTarget.showModal()
  }

  close() {
    this.dialogTarget.close()
  }
}
