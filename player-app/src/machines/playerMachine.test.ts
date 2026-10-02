import { describe, it, expect } from "vitest"
import { reducer } from "./playerMachine"
import type { PlayerState } from "./playerMachine"
import { mockManifestResponse } from "../__mocks__/manifest"

describe("playerMachine reducer", () => {
  const loading: PlayerState = { status: "loading" }
  const registering: PlayerState = { status: "registering" }
  const pairing: PlayerState = { status: "pairing", code: "ABC123", expiresAt: new Date() }
  const loadingManifest: PlayerState = { status: "loading_manifest" }
  const manifest = mockManifestResponse()
  const playing: PlayerState = { status: "playing", manifest, contentVersion: 1700000000 }
  const idle: PlayerState = { status: "idle", contentVersion: 1700000000 }

  describe("REGISTER", () => {
    it("transitions to registering", () => {
      expect(reducer(loading, { type: "REGISTER" })).toEqual({ status: "registering" })
    })
  })

  describe("REGISTERED", () => {
    it("transitions to pairing with code and expiry", () => {
      const expiresAt = new Date("2026-10-01T12:00:00Z")
      const result = reducer(registering, { type: "REGISTERED", code: "XYZ789", expiresAt })
      expect(result).toEqual({ status: "pairing", code: "XYZ789", expiresAt })
    })
  })

  describe("CODE_EXPIRED", () => {
    it("stays in pairing with a new code", () => {
      const expiresAt = new Date("2026-10-01T13:00:00Z")
      const result = reducer(pairing, { type: "CODE_EXPIRED", code: "NEW456", expiresAt })
      expect(result).toEqual({ status: "pairing", code: "NEW456", expiresAt })
    })
  })

  describe("PAIRED", () => {
    it("transitions to loading_manifest", () => {
      expect(reducer(pairing, { type: "PAIRED" })).toEqual({ status: "loading_manifest" })
    })
  })

  describe("ALREADY_PAIRED", () => {
    it("transitions to loading_manifest", () => {
      expect(reducer(loading, { type: "ALREADY_PAIRED" })).toEqual({ status: "loading_manifest" })
    })
  })

  describe("MANIFEST_LOADED", () => {
    it("transitions to playing with manifest and version", () => {
      const result = reducer(loadingManifest, { type: "MANIFEST_LOADED", manifest, contentVersion: 123 })
      expect(result).toEqual({ status: "playing", manifest, contentVersion: 123 })
    })
  })

  describe("NO_CONTENT", () => {
    it("transitions to idle", () => {
      const result = reducer(loadingManifest, { type: "NO_CONTENT", contentVersion: null })
      expect(result).toEqual({ status: "idle", contentVersion: null })
    })
  })

  describe("CONTENT_CHANGED", () => {
    it("transitions playing to loading_manifest", () => {
      expect(reducer(playing, { type: "CONTENT_CHANGED" })).toEqual({ status: "loading_manifest" })
    })

    it("transitions idle to loading_manifest", () => {
      expect(reducer(idle, { type: "CONTENT_CHANGED" })).toEqual({ status: "loading_manifest" })
    })
  })

  describe("UNPAIRED", () => {
    it("transitions to unpaired", () => {
      expect(reducer(playing, { type: "UNPAIRED" })).toEqual({ status: "unpaired" })
    })
  })

  describe("AUTH_FAILED", () => {
    it("transitions to registering from any state", () => {
      expect(reducer(loading, { type: "AUTH_FAILED" })).toEqual({ status: "registering" })
      expect(reducer(pairing, { type: "AUTH_FAILED" })).toEqual({ status: "registering" })
    })
  })

  describe("ERROR", () => {
    it("preserves lastGoodState when transitioning from playing", () => {
      const result = reducer(playing, { type: "ERROR", error: "Network failed" })
      expect(result).toEqual({
        status: "error",
        error: "Network failed",
        lastGoodState: playing,
      })
    })

    it("preserves lastGoodState when transitioning from idle", () => {
      const result = reducer(idle, { type: "ERROR", error: "Oops" })
      expect(result).toEqual({
        status: "error",
        error: "Oops",
        lastGoodState: idle,
      })
    })

    it("sets lastGoodState to null from non-content states", () => {
      const result = reducer(pairing, { type: "ERROR", error: "Failed" })
      expect(result).toEqual({
        status: "error",
        error: "Failed",
        lastGoodState: null,
      })
    })
  })
})
