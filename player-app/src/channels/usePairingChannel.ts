import { useEffect, useRef, type RefObject } from "react"
import type { Consumer, Subscription } from "@rails/actioncable"

interface UsePairingChannelOptions {
  consumer: RefObject<Consumer | null>
  code: string | null
  onPaired: () => void
}

export function usePairingChannel({ consumer, code, onPaired }: UsePairingChannelOptions) {
  const subscriptionRef = useRef<Subscription | null>(null)

  useEffect(() => {
    if (!consumer.current || !code) return

    subscriptionRef.current = consumer.current.subscriptions.create(
      { channel: "PairingChannel", code },
      {
        received(data: { paired?: boolean }) {
          if (data.paired) onPaired()
        },
      },
    )

    return () => {
      subscriptionRef.current?.unsubscribe()
      subscriptionRef.current = null
    }
  }, [consumer, code, onPaired])
}
