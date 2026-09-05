import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "openIcon", "closeIcon"]

  toggle() {
    const isOpen = !this.menuTarget.classList.contains("hidden")

    this.menuTarget.classList.toggle("hidden")
    this.openIconTarget.classList.toggle("hidden", !isOpen)
    this.closeIconTarget.classList.toggle("hidden", isOpen)
  }
}
