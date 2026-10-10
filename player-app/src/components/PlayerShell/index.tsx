import { useEffect, useCallback } from "react"
import { useQueryClient } from "@tanstack/react-query"
import { useAuth } from "../../context/AuthContext"
import { usePlayerMachine } from "../../machines/playerMachine"
import { useConsumer } from "../../channels/useConsumer"
import { usePairingChannel } from "../../channels/usePairingChannel"
import { useScreenChannel } from "../../channels/useScreenChannel"
import { usePlayerQuery } from "../../queries/usePlayerQuery"
import { useManifestQuery } from "../../queries/useManifestQuery"
import { useHeartbeat } from "../../queries/useHeartbeat"
import { api, ApiError } from "../../api/client"
import { track } from "../../analytics"
import { preloadManifestImages } from "../../utils/preloadImages"
import { PairingScreen } from "../screens/PairingScreen"
import { Slideshow } from "../playback/Slideshow"
import { Experience } from "../playback/Experience"
import { IdleScreen } from "../screens/IdleScreen"
import { ErrorScreen } from "../screens/ErrorScreen"
import type { ApiResponse, RegistrationResponse } from "../../types"

export function PlayerShell() {
  const { token, publicId, isAuthenticated, register, clear } = useAuth()
  const [state, dispatch] = usePlayerMachine()
  const consumer = useConsumer(token)
  const queryClient = useQueryClient()

  // Check player status on load when authenticated
  const { data: playerStatus, error: playerError } = usePlayerQuery(isAuthenticated && state.status === "loading")

  // Handle initial status check
  useEffect(() => {
    if (state.status !== "loading") return

    if (!isAuthenticated) {
      dispatch({ type: "REGISTER" })
      return
    }

    if (playerError) {
      if (playerError instanceof ApiError && playerError.status === 401) {
        clear()
        dispatch({ type: "AUTH_FAILED" })
      } else {
        dispatch({ type: "ERROR", error: playerError.message })
      }
      return
    }

    if (playerStatus) {
      if (playerStatus.paired) {
        dispatch({ type: "ALREADY_PAIRED" })
      } else {
        // Authenticated but not paired — need to refresh pairing code
        refreshPairingCode()
      }
    }
  }, [state.status, isAuthenticated, playerStatus, playerError])

  // Register new player
  useEffect(() => {
    if (state.status !== "registering") return

    async function doRegister() {
      try {
        const res = await api<ApiResponse<RegistrationResponse>>("/api/v1/players", {
          method: "POST",
          body: JSON.stringify({
            screen_width: screen.width,
            screen_height: screen.height,
            touch_capable: navigator.maxTouchPoints > 0,
          }),
        })
        register(res.data)
        dispatch({
          type: "REGISTERED",
          code: res.data.pairing_code,
          expiresAt: new Date(res.data.expires_at),
        })
      } catch (err) {
        dispatch({ type: "ERROR", error: "Failed to register device" })
      }
    }
    doRegister()
  }, [state.status, register])

  // Fetch manifest when loading_manifest
  const { data: manifest, error: manifestError } = useManifestQuery(
    state.status === "loading_manifest" || state.status === "playing" || state.status === "idle",
  )

  useEffect(() => {
    if (state.status !== "loading_manifest") return

    if (manifestError) {
      dispatch({ type: "ERROR", error: "Failed to load content" })
      return
    }

    if (manifest) {
      const version = manifest.screen_content?.updated_at ?? null
      if (manifest.contentable) {
        preloadManifestImages(manifest).then(() => {
          dispatch({ type: "MANIFEST_LOADED", manifest, contentVersion: version })
        })
      } else {
        dispatch({ type: "NO_CONTENT", contentVersion: version })
      }
    }
  }, [state.status, manifest, manifestError])

  // Update manifest when it changes (from invalidation)
  useEffect(() => {
    if (state.status !== "playing" && state.status !== "idle") return
    if (!manifest) return

    const version = manifest.screen_content?.updated_at ?? null
    if (manifest.contentable) {
      if (state.status !== "playing" || manifest !== state.manifest) {
        dispatch({ type: "MANIFEST_LOADED", manifest, contentVersion: version })
      }
    } else if (state.status !== "idle") {
      dispatch({ type: "NO_CONTENT", contentVersion: version })
    }
  }, [manifest])

  // Analytics — fire events on state transitions
  useEffect(() => {
    if (state.status !== "playing") return

    const m = state.manifest
    track("content.loaded", {
      screen_pid: m.screen_pid,
      screen_content_pid: m.screen_content?.pid,
      account_pid: m.account_pid,
      content_type: m.contentable?.type,
      content_pid: m.contentable?.pid,
    })

    track("device.connected", {
      screen_pid: m.screen_pid,
      player_pid: publicId,
      account_pid: m.account_pid,
    })
  }, [state.status === "playing" ? state.manifest : null])

  // Heartbeat — only when playing or idle
  const contentVersion = state.status === "playing" || state.status === "idle" ? state.contentVersion : null
  useHeartbeat(state.status === "playing" || state.status === "idle", contentVersion)

  // Pairing channel
  const pairingCode = state.status === "pairing" ? state.code : null
  const onPaired = useCallback(() => dispatch({ type: "PAIRED" }), [dispatch])
  usePairingChannel({ consumer, code: pairingCode, onPaired })

  // Screen channel
  const onContentChanged = useCallback(() => {
    queryClient.invalidateQueries({ queryKey: ["manifest"] })
  }, [queryClient])
  const onUnpaired = useCallback(() => dispatch({ type: "UNPAIRED" }), [dispatch])
  useScreenChannel({
    consumer,
    enabled: state.status === "playing" || state.status === "idle",
    onContentChanged,
    onUnpaired,
  })

  // Code expiry handler
  const onCodeExpired = useCallback(() => {
    refreshPairingCode()
  }, [])

  async function refreshPairingCode() {
    try {
      const res = await api<ApiResponse<{ pairing_code: string; expires_at: string }>>("/api/v1/player/pairing_code", {
        method: "POST",
      })
      dispatch({
        type: state.status === "pairing" ? "CODE_EXPIRED" : "REGISTERED",
        code: res.data.pairing_code,
        expiresAt: new Date(res.data.expires_at),
      })
    } catch {
      dispatch({ type: "ERROR", error: "Failed to refresh pairing code" })
    }
  }

  // Render based on state
  switch (state.status) {
    case "loading":
    case "registering":
    case "loading_manifest":
      return (
        <div className="flex items-center justify-center h-dvh bg-black">
          <div className="w-8 h-8 border-2 border-white/20 border-t-white rounded-full animate-spin" />
        </div>
      )

    case "pairing":
      return <PairingScreen code={state.code} expiresAt={state.expiresAt} onCodeExpired={onCodeExpired} />

    case "playing": {
      const { contentable } = state.manifest
      if (contentable?.type === "Playlist") {
        return <Slideshow manifest={state.manifest} />
      }
      if (contentable?.type === "Experience") {
        return <Experience manifest={state.manifest} />
      }
      return <IdleScreen />
    }

    case "idle":
      return <IdleScreen />

    case "unpaired":
      // Brief unpaired screen, then transition to pairing
      return <UnpairedTransition onComplete={() => refreshPairingCode()} />

    case "error":
      return <ErrorScreen error={state.error} />
  }
}

function UnpairedTransition({ onComplete }: { onComplete: () => void }) {
  useEffect(() => {
    const timer = setTimeout(onComplete, 2000)
    return () => clearTimeout(timer)
  }, [onComplete])

  return (
    <div className="flex flex-col items-center justify-center h-dvh bg-black text-white gap-4">
      <p className="text-2xl text-white/30 font-semibold">Player not paired</p>
      <p className="text-sm text-white/20">Returning to pairing screen...</p>
    </div>
  )
}
