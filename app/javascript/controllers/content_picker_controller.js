import { Controller } from "@hotwired/stimulus"

// Handles ad card selection and duration slider in the "Add content" modal.
export default class extends Controller {
  static targets = ["card", "adIdField", "durationField", "durationDisplay", "submitBtn"]

  select(event) {
    const card = event.currentTarget
    const adId = card.dataset.adId

    // Toggle selection
    this.cardTargets.forEach(c => c.classList.remove("ring-2", "ring-indigo-500"))
    card.classList.add("ring-2", "ring-indigo-500")

    this.adIdFieldTarget.value = adId
    this.submitBtnTarget.disabled = false
    this.submitBtnTarget.classList.remove("opacity-50", "cursor-not-allowed")
  }

  updateDuration(event) {
    const value = event.target.value
    if (this.hasDurationFieldTarget) this.durationFieldTarget.value = value
    this.durationDisplayTarget.textContent = `${value}s`
  }
}
