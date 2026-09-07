import { Controller } from "@hotwired/stimulus"
import "ahoy"
import Analytics from "analytics"

export default class extends Controller {
  static targets = ["slide", "counter", "gallery", "navControl", "floorPlanOverlay"]
  static values = {
    idleTimeout: { type: Number, default: 30 },
    slideCount: { type: Number, default: 0 },
    experienceId: Number,
    screenId: Number,
    screenContentId: Number,
    accountId: Number
  }

  connect() {
    this.currentSlide = 0
    this.idleTimer = null
    this.autoplayTimer = null
    this.idle = true
    this.sessionStartTime = null
    this.floorPlanOpenTime = null
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
    this.trackNavigation("next")
  }

  prev() {
    this.goToSlide((this.currentSlide - 1 + this.slideTargets.length) % this.slideTargets.length)
    this.trackNavigation("prev")
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
    this.autoplayTimer = setInterval(() => {
      // Auto-advance without tracking navigation
      const next = (this.currentSlide + 1) % this.slideTargets.length
      this.goToSlide(next)
    }, 5000)
  }

  stopAutoplay() {
    clearInterval(this.autoplayTimer)
    this.autoplayTimer = null
  }

  // Idle timer
  resetIdleTimer() {
    if (this.idle && this.hasTouch) {
      // Session starts — new Ahoy visit for kiosk session
      window.ahoy.reset()
      this.idle = false
      this.sessionStartTime = Date.now()

      Analytics.create("interaction.started", {
        experience_id: this.experienceIdValue,
        screen_id: this.screenIdValue,
        screen_content_id: this.screenContentIdValue,
        account_id: this.accountIdValue
      })

      this.stopAutoplay()
      this.showNavControls()
    }

    clearTimeout(this.idleTimer)
    this.idleTimer = setTimeout(() => this.enterIdleMode(), this.idleTimeoutValue * 1000)
  }

  enterIdleMode() {
    if (!this.idle && this.sessionStartTime) {
      const duration = Math.round((Date.now() - this.sessionStartTime) / 1000)

      Analytics.create("interaction.ended", {
        experience_id: this.experienceIdValue,
        screen_id: this.screenIdValue,
        screen_content_id: this.screenContentIdValue,
        duration: duration,
        account_id: this.accountIdValue
      })
    }

    this.idle = true
    this.sessionStartTime = null
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
      this.floorPlanOpenTime = Date.now()

      Analytics.create("interaction.opened", {
        experience_id: this.experienceIdValue,
        screen_content_id: this.screenContentIdValue,
        target: "floor_plan",
        account_id: this.accountIdValue
      })
    }
  }

  hideFloorPlans() {
    if (this.hasFloorPlanOverlayTarget) {
      this.floorPlanOverlayTarget.classList.remove("flex")
      this.floorPlanOverlayTarget.classList.add("hidden")

      const viewDuration = this.floorPlanOpenTime
        ? Math.round((Date.now() - this.floorPlanOpenTime) / 1000)
        : 0

      Analytics.create("interaction.closed", {
        experience_id: this.experienceIdValue,
        screen_content_id: this.screenContentIdValue,
        target: "floor_plan",
        account_id: this.accountIdValue,
        view_duration: viewDuration
      })

      this.floorPlanOpenTime = null
    }
  }

  // Analytics helpers
  trackNavigation(direction) {
    if (this.idle) return // Don't track autoplay navigation

    Analytics.create("interaction.navigated", {
      experience_id: this.experienceIdValue,
      screen_content_id: this.screenContentIdValue,
      direction: direction,
      account_id: this.accountIdValue,
      photo_index: this.currentSlide
    })
  }
}
