import { useEffect, useRef } from "react"
import { createConsumer, type Consumer } from "@rails/actioncable"

const CABLE_URL = import.meta.env.VITE_CABLE_URL || ""

export function useConsumer(token: string | null) {
  const consumerRef = useRef<Consumer | null>(null)

  useEffect(() => {
    if (!token) return

    const base = CABLE_URL || `${location.protocol === "https:" ? "wss:" : "ws:"}//${location.host}`
    const wsUrl = `${base}/cable?token=${encodeURIComponent(token)}`
    consumerRef.current = createConsumer(wsUrl)

    return () => {
      consumerRef.current?.disconnect()
      consumerRef.current = null
    }
  }, [token])

  return consumerRef
}
