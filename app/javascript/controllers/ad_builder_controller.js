import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form"]
  static values = { previewUrl: String }

  connect() {
    this.timeout = null
  }

  disconnect() {
    clearTimeout(this.timeout)
  }

  // Select/radio change — immediate preview update
  changed() {
    this.submitPreview()
  }

  // Text input — debounced 300ms
  typed() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => this.submitPreview(), 300)
  }

  async submitPreview() {
    if (!this.hasFormTarget || !this.previewUrlValue) return

    const formData = new FormData(this.formTarget)

    try {
      const response = await fetch(this.previewUrlValue, {
        method: "POST",
        body: formData,
        headers: {
          "Accept": "text/vnd.turbo-stream.html",
          "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
        }
      })

      if (response.ok) {
        const html = await response.text()
        window.Turbo.renderStreamMessage(html)
      }
    } catch {
      // Network error — silently skip preview update
    }
  }
}
