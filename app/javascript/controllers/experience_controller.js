import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["slide", "counter", "gallery", "navControl", "floorPlanOverlay"]
  static values = { idleTimeout: { type: Number, default: 30 }, slideCount: { type: Number, default: 0 } }

  connect() {
    this.currentSlide = 0
    this.idleTimer = null
    this.autoplayTimer = null
    this.hasTouch = "ontouchstart" in window || navigator.maxTouchPoints > 0

    if (this.hasTouch) {
      this.showNavControls()
    }

    this.startAutoplay()
    this.resetIdleTimer()

    // Any interaction resets idle
    this.element.addEventListener("click", () => this.resetIdleTimer())
    this.element.addEventListener("touchstart", () => this.resetIdleTimer())
  }

  disconnect() {
    clearTimeout(this.idleTimer)
    clearInterval(this.autoplayTimer)
  }

  // Photo navigation
  next() {
    this.goToSlide((this.currentSlide + 1) % this.slideTargets.length)
  }

  prev() {
    this.goToSlide((this.currentSlide - 1 + this.slideTargets.length) % this.slideTargets.length)
  }

  goToSlide(index) {
    this.slideTargets.forEach((slide, i) => {
      slide.classList.toggle("opacity-100", i === index)
      slide.classList.toggle("opacity-0", i !== index)
    })
    this.currentSlide = index
    if (this.hasCounterTarget) {
      this.counterTarget.textContent = index + 1
    }
  }

  // Autoplay (idle mode)
  startAutoplay() {
    if (this.slideTargets.length <= 1) return
    this.autoplayTimer = setInterval(() => this.next(), 5000)
  }

  stopAutoplay() {
    clearInterval(this.autoplayTimer)
    this.autoplayTimer = null
  }

  // Idle timer
  resetIdleTimer() {
    // On interaction: stop autoplay, show controls
    if (this.hasTouch) {
      this.stopAutoplay()
      this.showNavControls()
    }

    clearTimeout(this.idleTimer)
    this.idleTimer = setTimeout(() => this.enterIdleMode(), this.idleTimeoutValue * 1000)
  }

  enterIdleMode() {
    this.hideNavControls()
    this.startAutoplay()
  }

  // Nav controls visibility
  showNavControls() {
    this.navControlTargets.forEach(el => el.classList.replace("opacity-0", "opacity-100"))
  }

  hideNavControls() {
    this.navControlTargets.forEach(el => el.classList.replace("opacity-100", "opacity-0"))
  }

  // Floor plans overlay
  showFloorPlans() {
    if (this.hasFloorPlanOverlayTarget) {
      this.floorPlanOverlayTarget.classList.remove("hidden")
      this.floorPlanOverlayTarget.classList.add("flex")
    }
  }

  hideFloorPlans() {
    if (this.hasFloorPlanOverlayTarget) {
      this.floorPlanOverlayTarget.classList.remove("flex")
      this.floorPlanOverlayTarget.classList.add("hidden")
    }
  }
}
