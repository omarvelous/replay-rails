declare module "ahoy.js" {
  interface Ahoy {
    configure(options: {
      visitsUrl?: string
      eventsUrl?: string
      cookieDomain?: string | null
      visitDuration?: number
      withCredentials?: boolean
    }): void
    track(name: string, properties?: Record<string, unknown>): void
    trackView(additionalProperties?: Record<string, unknown>): void
    reset(): void
    start(): void
  }

  const ahoy: Ahoy
  export default ahoy
}
