# Plan: Storybook for React Player App

**Created:** 2026-10-01
**Status:** Draft
**Branch:** TBD

## Problem

Player components (Slideshow, Experience, PairingScreen, etc.)
can only be tested by running the full stack — Rails API, Docker,
pairing a device. No way to develop or review components in
isolation with different data states.

## Goals

1. Storybook in `player-app/` for visual component development
2. Stories for every player state (pairing, playing, idle, error)
3. Mock manifest data — no Rails API required
4. Preview all ad types (listing, agent, brand, collection)
5. Preview edge cases (no image, long text, missing agent)

## Setup

```bash
cd player-app
npx storybook@latest init --type react
```

This adds `.storybook/` config and `src/**/*.stories.tsx` convention.

## Stories

```
src/components/
├── PairingScreen.stories.tsx     # code display, countdown at various times
├── Slideshow.stories.tsx         # listing ad, agent ad, brand ad, collection
├── Experience.stories.tsx        # with/without agent, with/without photos
├── IdleScreen.stories.tsx        # static
├── ErrorScreen.stories.tsx       # with error message
```

### Slideshow stories

- `ListingAd` — hero layout with image, badge, price, specs
- `OpenHouseAd` — split layout with event date/time
- `PriceReduction` — original price strikethrough
- `AgentAd` — profile layout with photo, contact info
- `BrandAd` — hero layout, no listing data
- `NoImage` — ad without an attached image
- `SingleAd` — playlist with one ad (no rotation)

### Mock data

Create `src/__mocks__/manifest.ts` with factory functions:

```typescript
export function mockManifest(overrides?: Partial<ManifestResponse>): ManifestResponse
export function mockPlaylistAd(overrides?: Partial<ManifestPlaylistAd>): ManifestPlaylistAd
export function mockListingAd(overrides?: Partial<ManifestListingAd>): ManifestListingAd
```

Reusable across stories and future tests.

## Execution

```
1. npx storybook@latest init --type react
   COMMIT

2. Mock data factories in src/__mocks__/manifest.ts
   COMMIT

3. Stories for PairingScreen, IdleScreen, ErrorScreen
   COMMIT

4. Stories for Slideshow (all ad types + edge cases)
   COMMIT

5. Stories for Experience
   COMMIT
```

## Notes

- Storybook runs independently: `npm run storybook` (port 6006)
- No Docker dependency — pure frontend
- Add to Makefile: `make storybook`
- Components must accept props (not fetch internally) for
  Storybook compatibility — current design already does this
