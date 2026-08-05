import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]
  static values = { current: { type: String, default: "overview" } }

  switch(event) {
    this.currentValue = event.currentTarget.dataset.tab
    this.update()
  }

  update() {
    this.tabTargets.forEach(tab => {
      const active = tab.dataset.tab === this.currentValue
      tab.classList.toggle("tab-active", active)
    })

    this.panelTargets.forEach(panel => {
      panel.classList.toggle("hidden", panel.dataset.tab !== this.currentValue)
    })
  }

  connect() {
    this.update()
  }
}
