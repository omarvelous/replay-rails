import ahoy from "ahoy.js"
import { EVENTS } from "./catalog"

ahoy.configure({
  visitsUrl: "/ahoy/visits",
  eventsUrl: "/ahoy/events",
})

export function track(eventName: string, properties: Record<string, unknown>) {
  const schema = EVENTS[eventName]
  if (!schema) {
    console.error(`[Analytics] Unknown event: "${eventName}"`)
    return
  }

  const errors: string[] = []
  for (const [key, config] of Object.entries(schema.properties)) {
    if (config.required && !(key in properties)) {
      errors.push(`${eventName}: "${key}" is required`)
    }
  }

  if (errors.length > 0) {
    console.error("[Analytics]", ...errors)
    return
  }

  ahoy.track(eventName, properties)
}
