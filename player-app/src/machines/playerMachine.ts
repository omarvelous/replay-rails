import { useReducer } from "react"
import type { ManifestResponse } from "../types"

// States — each variant is the only shape the state can take
export type PlayerState =
  | { status: "loading" }
  | { status: "registering" }
  | { status: "pairing"; code: string; expiresAt: Date }
  | { status: "loading_manifest" }
  | { status: "playing"; manifest: ManifestResponse; contentVersion: number | null }
  | { status: "idle"; contentVersion: number | null }
  | { status: "unpaired" }
  | { status: "error"; error: string; lastGoodState: PlayerState | null }

// Events — all possible transitions
export type PlayerEvent =
  | { type: "REGISTER" }
  | { type: "REGISTERED"; code: string; expiresAt: Date }
  | { type: "PAIRED" }
  | { type: "MANIFEST_LOADED"; manifest: ManifestResponse; contentVersion: number | null }
  | { type: "NO_CONTENT"; contentVersion: number | null }
  | { type: "CONTENT_CHANGED" }
  | { type: "UNPAIRED" }
  | { type: "AUTH_FAILED" }
  | { type: "CODE_EXPIRED"; code: string; expiresAt: Date }
  | { type: "ERROR"; error: string }
  | { type: "ALREADY_PAIRED" }

const initialState: PlayerState = { status: "loading" }

function reducer(state: PlayerState, event: PlayerEvent): PlayerState {
  switch (event.type) {
    case "REGISTER":
      return { status: "registering" }

    case "REGISTERED":
      return { status: "pairing", code: event.code, expiresAt: event.expiresAt }

    case "CODE_EXPIRED":
      return { status: "pairing", code: event.code, expiresAt: event.expiresAt }

    case "PAIRED":
    case "ALREADY_PAIRED":
      return { status: "loading_manifest" }

    case "MANIFEST_LOADED":
      return { status: "playing", manifest: event.manifest, contentVersion: event.contentVersion }

    case "NO_CONTENT":
      return { status: "idle", contentVersion: event.contentVersion }

    case "CONTENT_CHANGED":
      return { status: "loading_manifest" }

    case "UNPAIRED":
      return { status: "unpaired" }

    case "AUTH_FAILED":
      return { status: "registering" }

    case "ERROR": {
      const lastGood = state.status === "playing" || state.status === "idle" ? state : null
      return { status: "error", error: event.error, lastGoodState: lastGood }
    }

    default:
      return state
  }
}

export function usePlayerMachine() {
  return useReducer(reducer, initialState)
}
