import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["slide"]

  connect() {
    this.currentIndex = 0
    this.scheduleNext()
  }

  disconnect() {
    clearTimeout(this.timer)
  }

  scheduleNext() {
    const currentSlide = this.slideTargets[this.currentIndex]
    const duration = parseInt(currentSlide.dataset.duration || 10, 10) * 1000

    this.timer = setTimeout(() => {
      this.advance()
    }, duration)
  }

  advance() {
    const slides = this.slideTargets
    if (slides.length <= 1) return

    slides[this.currentIndex].classList.replace("opacity-100", "opacity-0")
    this.currentIndex = (this.currentIndex + 1) % slides.length
    slides[this.currentIndex].classList.replace("opacity-0", "opacity-100")

    this.scheduleNext()
  }
}
