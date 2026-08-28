# Follow-up: Live Preview via Turbo Frame

## Approach
- Wrap preview canvas in `turbo_frame_tag "ad_preview"`
- Add `POST /ads/:type/preview` endpoint per type controller (no save, just render)
- On badge/listing/theme/layout change, `requestSubmit` to the preview endpoint
- Server renders the real layout partial inside the frame
- Headline/body: keep Stimulus text-swap for instant feedback (no round-trip)

## Blocked on
- All 4 type controllers being wired up (Tasks 18-24)

## When
- After Phase E is complete
