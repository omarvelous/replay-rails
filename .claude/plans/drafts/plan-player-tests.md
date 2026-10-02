# Plan: React Player App Tests

**Created:** 2026-10-01
**Status:** Draft
**Branch:** TBD

## Problem

The React player app has zero tests. Components, hooks, the state
machine, and the API client are all untested. Changes can break
the player silently.

## Goals

1. Vitest + React Testing Library for component and hook tests
2. State machine has full coverage (every transition)
3. Components render correctly for each state
4. API client handles success, error, and auth flows
5. Mock data factories shared with future Storybook stories

## Tech stack

- **Vitest** — Vite-native, fast, Jest-compatible API
- **React Testing Library** — test user-visible behavior, not internals
- **@testing-library/user-event** — realistic interactions
- **MSW (Mock Service Worker)** — intercept API calls at the network
  level instead of mocking fetch directly. Tests the full request
  path including the API client.

## Test structure

```
player-app/
├── src/
│   ├── __mocks__/
│   │   └── manifest.ts             # factory functions for test data
│   ├── machines/
│   │   └── playerMachine.test.ts   # state machine transitions
│   ├── api/
│   │   └── client.test.ts          # API client auth, error handling
│   ├── context/
│   │   └── AuthContext.test.tsx     # register, clear, localStorage sync
│   ├── components/
│   │   ├── PairingScreen.test.tsx   # code display, countdown
│   │   ├── Slideshow.test.tsx       # ad rotation, content rendering
│   │   ├── Experience.test.tsx      # listing details rendering
│   │   ├── IdleScreen.test.tsx      # static render
│   │   └── ErrorScreen.test.tsx     # error message display
│   └── queries/
│       └── useHeartbeat.test.tsx    # version comparison, invalidation
├── vitest.config.ts
└── vitest.setup.ts
```

## Test categories

### 1. State machine (pure logic, no React)

The reducer is a pure function — easiest to test, highest value.
Every state + event combination:

```typescript
describe("playerMachine", () => {
  it("LOADING → REGISTER when no token")
  it("LOADING → ALREADY_PAIRED when paired")
  it("REGISTERING → PAIRING on REGISTERED")
  it("PAIRING → LOADING_MANIFEST on PAIRED")
  it("PAIRING → PAIRING on CODE_EXPIRED (new code)")
  it("LOADING_MANIFEST → PLAYING on MANIFEST_LOADED")
  it("LOADING_MANIFEST → IDLE on NO_CONTENT")
  it("PLAYING → LOADING_MANIFEST on CONTENT_CHANGED")
  it("PLAYING → UNPAIRED on UNPAIRED")
  it("PLAYING → ERROR on ERROR (preserves lastGoodState)")
  it("any → REGISTERING on AUTH_FAILED")
  it("IDLE → LOADING_MANIFEST on CONTENT_CHANGED")
})
```

### 2. API client (unit)

```typescript
describe("api client", () => {
  it("includes bearer token in Authorization header")
  it("does not include Authorization when no token set")
  it("throws ApiError on non-2xx response")
  it("parses JSON response body")
})
```

### 3. AuthContext (integration)

```typescript
describe("AuthContext", () => {
  it("hydrates token from localStorage on mount")
  it("returns isAuthenticated: false when no token")
  it("register() stores token in state and localStorage")
  it("clear() removes token from state and localStorage")
  it("sets API client token on mount")
})
```

### 4. Components (render tests)

Test what the user sees, not implementation details:

**PairingScreen:**
```typescript
it("displays the pairing code")
it("shows countdown timer")
it("calls onCodeExpired when timer reaches zero")
```

**Slideshow:**
```typescript
it("renders the first ad's headline and image")
it("renders listing ad badge and price")
it("renders agent ad with name and photo")
it("renders brand ad with headline only")
it("advances to next ad after duration")
```

**Experience:**
```typescript
it("renders listing address and price")
it("renders listing specs (beds, baths, sqft)")
it("renders agent card when agent present")
it("renders without agent when none assigned")
it("renders listing photo")
```

**IdleScreen / ErrorScreen:**
```typescript
it("renders no content message")
it("renders error message")
```

### 5. Hooks with MSW (integration)

MSW intercepts fetch at the network level — tests the full
chain from hook → API client → response handling:

```typescript
describe("useHeartbeat", () => {
  it("sends heartbeat every 30 seconds")
  it("invalidates manifest query when content_version changes")
  it("does not invalidate when version is the same")
})

describe("useManifestQuery", () => {
  it("fetches manifest and returns data")
  it("does not refetch when staleTime is Infinity")
})
```

### 6. Mock data factories

Shared between tests and Storybook:

```typescript
// src/__mocks__/manifest.ts
export function mockManifestResponse(overrides?): ManifestResponse
export function mockPlaylist(overrides?): ManifestPlaylist
export function mockPlaylistAd(overrides?): ManifestPlaylistAd
export function mockListingAd(overrides?): ManifestListingAd
export function mockAgentAd(overrides?): ManifestAgentAd
export function mockBrandAd(overrides?): ManifestBrandAd
export function mockListing(overrides?): ManifestListing
export function mockAgent(overrides?): ManifestAgent
export function mockAttachment(overrides?): ManifestAttachment
```

## What NOT to test

- **PlayerShell orchestration** — heavily coupled to hooks,
  context, and side effects. Testing the state machine and
  individual components covers the logic. Integration testing
  PlayerShell requires mocking too many things to be valuable.
- **ActionCable subscriptions** — `@rails/actioncable` is a
  third-party lib. Test the callbacks (onPaired, onContentChanged)
  not the subscription wiring.
- **TanStack Query internals** — don't test that React Query
  caches or refetches. Test that your queryFn returns the right
  data and your onSuccess callbacks do the right thing.

## Execution

```
1. Install vitest, @testing-library/react, @testing-library/jest-dom,
   @testing-library/user-event, jsdom, msw
   Configure vitest.config.ts and vitest.setup.ts
   COMMIT

2. Mock data factories in src/__mocks__/manifest.ts
   COMMIT

3. State machine tests (playerMachine.test.ts)
   COMMIT

4. API client tests (client.test.ts)
   COMMIT

5. AuthContext tests (AuthContext.test.tsx)
   COMMIT

6. Component render tests (PairingScreen, Slideshow, Experience,
   IdleScreen, ErrorScreen)
   COMMIT

7. Hook integration tests with MSW (useHeartbeat, useManifestQuery)
   COMMIT

8. Add `make player-test` to Makefile
   COMMIT
```
