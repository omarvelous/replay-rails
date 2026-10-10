import { useEffect, useRef, type RefObject } from "react"
import { useQueryClient } from "@tanstack/react-query"
import type { Consumer, Subscription } from "@rails/actioncable"

interface UseScreenChannelOptions {
  consumer: RefObject<Consumer | null>
  enabled: boolean
  onContentChanged: () => void
  onUnpaired: () => void
}

export function useScreenChannel({ consumer, enabled, onContentChanged, onUnpaired }: UseScreenChannelOptions) {
  const subscriptionRef = useRef<Subscription | null>(null)
  const queryClient = useQueryClient()

  useEffect(() => {
    if (!consumer.current || !enabled) return

    subscriptionRef.current = consumer.current.subscriptions.create(
      { channel: "ScreenChannel" },
      {
        connected() {
          // Reconnected — refetch manifest in case we missed a broadcast
          queryClient.invalidateQueries({ queryKey: ["manifest"] })
        },
        received(data: { event?: string }) {
          if (data.event === "content_changed" || data.event === "content_nudge") {
            onContentChanged()
          }
          if (data.event === "unpaired") {
            onUnpaired()
          }
        },
        rejected() {
          onUnpaired()
        },
      },
    )

    return () => {
      subscriptionRef.current?.unsubscribe()
      subscriptionRef.current = null
    }
  }, [consumer, enabled, onContentChanged, onUnpaired, queryClient])
}
