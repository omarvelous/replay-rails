# Plan: App UX Fixes (Draft)

## Items

- **Screen status states** — The screens list page has hardcoded "Heartbeat 12s ago" text and only two states (Live/Idle based on playlist presence). Doesn't account for player state. Rethink to show four distinct states:
  - **No player** (gray) — no player assigned, heartbeat line: "No player assigned"
  - **Offline** (red/amber) — player paired but `online?` false, heartbeat line: "Last seen {time_ago}" or "Never connected"
  - **Online** (blue) — player paired and online but no playlist, heartbeat line: "Heartbeat {time_ago}"
  - **Live** (green) — player online + playlist assigned, heartbeat line: "Heartbeat {time_ago}"
  
  Applies to both grid and table views. Use `screen.player&.last_heartbeat_at` with `time_ago_in_words` for the heartbeat line. The status badge and heartbeat row logic need to be updated together.
