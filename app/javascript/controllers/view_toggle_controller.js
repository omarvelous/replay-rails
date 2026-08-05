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
      btn.classList.toggle("btn-active", active)
    })
  }

  connect() {
    this.update()
  }
}
