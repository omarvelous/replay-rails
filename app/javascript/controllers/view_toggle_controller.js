import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["view"]
  static values = { current: { type: String, default: "grid" } }

  switch(event) {
    this.currentValue = event.currentTarget.dataset.view
    this.update()
  }

  update() {
    this.viewTargets.forEach(view => {
      view.classList.toggle("hidden", view.dataset.view !== this.currentValue)
    })

    this.element.querySelectorAll("[data-view-btn]").forEach(btn => {
      const active = btn.dataset.view === this.currentValue
      if (active) {
        btn.classList.add("bg-gray-100", "text-gray-900")
        btn.classList.remove("text-gray-400")
      } else {
        btn.classList.remove("bg-gray-100", "text-gray-900")
        btn.classList.add("text-gray-400")
      }
    })
  }

  connect() {
    this.update()
  }
}
