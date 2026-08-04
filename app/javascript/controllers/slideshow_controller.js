import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["slide", "progress", "editLink"]

  connect() {
    this.currentIndex = 0
    this.startProgress()
  }

  disconnect() {
    clearTimeout(this.timer)
    cancelAnimationFrame(this.animationFrame)
  }

  startProgress() {
    const currentSlide = this.slideTargets[this.currentIndex]
    this.duration = parseInt(currentSlide.dataset.duration || 10, 10) * 1000
    this.startTime = performance.now()

    if (this.hasProgressTarget) {
      this.progressTarget.style.transition = "none"
      this.progressTarget.style.width = "0%"
    }

    this.tick()
  }

  tick() {
    const elapsed = performance.now() - this.startTime
    const fraction = Math.min(elapsed / this.duration, 1)

    if (this.hasProgressTarget) {
      this.progressTarget.style.width = `${fraction * 100}%`
    }

    if (fraction < 1) {
      this.animationFrame = requestAnimationFrame(() => this.tick())
    } else {
      this.advance()
    }
  }

  next() {
    this.goTo((this.currentIndex + 1) % this.slideTargets.length)
  }

  previous() {
    const length = this.slideTargets.length
    this.goTo((this.currentIndex - 1 + length) % length)
  }

  advance() {
    this.next()
  }

  goTo(index) {
    const slides = this.slideTargets
    if (slides.length <= 1) {
      this.startProgress()
      return
    }

    cancelAnimationFrame(this.animationFrame)
    slides[this.currentIndex].classList.replace("opacity-100", "opacity-0")
    this.currentIndex = index
    slides[this.currentIndex].classList.replace("opacity-0", "opacity-100")

    if (this.hasEditLinkTarget) {
      this.editLinkTargets.forEach((link, i) => {
        link.style.display = i === this.currentIndex ? "" : "none"
      })
    }

    this.startProgress()
  }
}
