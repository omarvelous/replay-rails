import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["backdrop", "panel"]

  connect() {
    console.log("[drawer] controller connected")
    const frame = this.element.querySelector("turbo-frame#drawer")
    if (!frame) { console.log("[drawer] no frame found!"); return }
    console.log("[drawer] observing frame", frame)

    this.observer = new MutationObserver(() => {
      if (frame.children.length > 0) {
        this.open()
      }
    })
    this.observer.observe(frame, { childList: true })

    this.handleEscape = (e) => {
      if (e.key === "Escape") this.close()
    }
  }

  disconnect() {
    this.observer?.disconnect()
    document.removeEventListener("keydown", this.handleEscape)
  }

  open() {
    console.log("[drawer] opening!")
    this.backdropTarget.classList.remove("hidden")
    this.panelTarget.classList.remove("translate-x-full")
    this.panelTarget.classList.add("translate-x-0")
    document.addEventListener("keydown", this.handleEscape)
    document.body.style.overflow = "hidden"
  }

  close() {
    this.backdropTarget.classList.add("hidden")
    this.panelTarget.classList.add("translate-x-full")
    this.panelTarget.classList.remove("translate-x-0")
    document.removeEventListener("keydown", this.handleEscape)
    document.body.style.overflow = ""
    const frame = this.element.querySelector("turbo-frame#drawer")
    if (frame) frame.innerHTML = ""
  }
}
