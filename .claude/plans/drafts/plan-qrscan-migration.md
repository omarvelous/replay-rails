# Plan: Migrate QrScan to Ahoy Event (Draft)

## Problem

`QrScan` is a standalone model that tracks QR code scans with its
own table, associations, and scopes. With the move to Ahoy for
unified event tracking, QR scans should ideally be an Ahoy event
(`qr.scanned`) rather than a separate model.

However, `QrScan` has relationships that make this non-trivial:

- `has_many :leads` — leads are attributed to the scan that
  created them
- `belongs_to :qr_code` — ties scan to the QR code record
- `belongs_to :ad, optional: true` — ties scan to the ad shown
- `belongs_to :screen, optional: true` — ties scan to the screen
- `scope :qualified` — scans with both ad and screen
- `store_accessor :context` — playlist_id, slide_position

The model is referenced in ~15 places across controllers, views,
helpers, and specs. Dashboard, screen show, listing show, and
agent show all query `QrScan` for counts.

## Questions to Resolve

1. How do leads reference scans if scans are Ahoy events?
   `visitable` links leads to visits, but a visit may contain
   multiple events — how to link to the specific scan event?

2. The `qualified` scope filters scans with ad + screen. How
   to replicate this as an Ahoy event query efficiently?

3. `QrScan` stores `ip_address` and `user_agent` — Ahoy visits
   already track these. Redundancy eliminated.

4. Migration path for existing `qr_scans` data?

5. Performance of jsonb property queries vs dedicated columns
   for high-volume scan counts on dashboards?

## Status

Deferred until after Ahoy analytics migration is complete.
Depends on `visitable` being established on Lead and the
governed events system being in production.
