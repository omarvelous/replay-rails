import { useEffect, useRef } from "react"
import { createConsumer, type Consumer } from "@rails/actioncable"

export function useConsumer(token: string | null) {
  const consumerRef = useRef<Consumer | null>(null)

  useEffect(() => {
    if (!token) return

    const wsUrl = `${location.protocol === "https:" ? "wss:" : "ws:"}//${location.host}/cable?token=${encodeURIComponent(token)}`
    consumerRef.current = createConsumer(wsUrl)

    return () => {
      consumerRef.current?.disconnect()
      consumerRef.current = null
    }
  }, [token])

  return consumerRef
}
