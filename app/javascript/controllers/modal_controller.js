import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog"]

  dialogTargetConnected() {
    this.observer = new MutationObserver(() => {
      const frame = this.dialogTarget.querySelector("turbo-frame#modal")
      if (frame?.children.length > 0) {
        this.open()
      } else {
        this.close()
      }
    })
    this.observer.observe(
      this.dialogTarget.querySelector("turbo-frame#modal"),
      { childList: true }
    )

    this.dialogTarget.addEventListener("close", () => {
      const frame = this.dialogTarget.querySelector("turbo-frame#modal")
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
