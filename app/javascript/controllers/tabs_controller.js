import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]
  static values = { current: { type: String, default: "overview" } }

  static classes = {
    active: ["border-indigo-500", "text-indigo-600"],
    inactive: ["border-transparent", "text-gray-500", "hover:border-gray-300", "hover:text-gray-700"]
  }

  switch(event) {
    this.currentValue = event.currentTarget.dataset.tab
    this.update()
  }

  update() {
    const activeClasses = ["border-indigo-500", "text-indigo-600"]
    const inactiveClasses = ["border-transparent", "text-gray-500", "hover:border-gray-300", "hover:text-gray-700"]

    this.tabTargets.forEach(tab => {
      const active = tab.dataset.tab === this.currentValue
      if (active) {
        tab.classList.remove(...inactiveClasses)
        tab.classList.add(...activeClasses)
      } else {
        tab.classList.remove(...activeClasses)
        tab.classList.add(...inactiveClasses)
      }
    })

    this.panelTargets.forEach(panel => {
      panel.classList.toggle("hidden", panel.dataset.tab !== this.currentValue)
    })
  }

  connect() {
    this.update()
  }
}
