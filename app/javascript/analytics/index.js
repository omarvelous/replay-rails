import "ahoy"
import { EVENTS } from "analytics/catalog"

class AnalyticsEvent {
  constructor(name, schema, properties) {
    this.name = name
    this.schema = schema
    this.properties = properties
    this.errors = []
  }

  get valid() {
    this.errors = []
    for (const [key, config] of Object.entries(this.schema)) {
      if (config.required && !(key in this.properties)) {
        this.errors.push(`${this.name}: "${key}" is required`)
      }
    }
    return this.errors.length === 0
  }

  create() {
    if (!this.valid) {
      console.error("[Analytics]", ...this.errors)
      return false
    }
    window.ahoy.track(this.name, this.properties)
    return true
  }
}

const Analytics = {
  create(eventName, properties = {}) {
    const schema = EVENTS[eventName]
    if (!schema) {
      console.error(`[Analytics] Unknown event: "${eventName}"`)
      return null
    }
    const event = new AnalyticsEvent(eventName, schema.properties, properties)
    event.create()
    return event
  }
}

export default Analytics
