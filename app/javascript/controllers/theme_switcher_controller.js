import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button"]
  static values = { current: { type: String, default: "minimal" } }

  themes = ["minimal", "bold", "warm"]

  connect() {
    const saved = localStorage.getItem("marketing-theme")
    if (saved && this.themes.includes(saved)) {
      this.currentValue = saved
    }
    this.apply()
  }

  switch(event) {
    this.currentValue = event.currentTarget.dataset.theme
    localStorage.setItem("marketing-theme", this.currentValue)
    this.apply()
  }

  apply() {
    document.documentElement.dataset.marketingTheme = this.currentValue
    this.buttonTargets.forEach((btn) => {
      const isActive = btn.dataset.theme === this.currentValue
      btn.classList.toggle("ring-2", isActive)
      btn.classList.toggle("ring-indigo-500", isActive)
      btn.classList.toggle("opacity-60", !isActive)
      btn.classList.toggle("opacity-100", isActive)
    })
  }
}
