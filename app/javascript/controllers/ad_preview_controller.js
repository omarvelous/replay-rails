import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["previewHeadline", "previewBody"]

  updateHeadline(event) {
    if (this.hasPreviewHeadlineTarget) {
      this.previewHeadlineTarget.textContent = event.target.value || "Your headline here"
    }
  }

  updateBody(event) {
    if (this.hasPreviewBodyTarget) {
      this.previewBodyTarget.textContent = event.target.value || "Add a subheadline or description"
    }
  }
}
