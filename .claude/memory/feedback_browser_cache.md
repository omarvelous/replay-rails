---
name: Browser cache on route changes
description: Route changes can appear broken due to browser caching old redirects — suggest incognito/cache clear before debugging
type: feedback
---

When route paths change (e.g., `/players/new` → `/player/new`), the browser may cache the old redirect. Always suggest clearing cookies/cache or using incognito before investigating further.

**Why:** Spent time debugging a "broken redirect" that was just a cached 302 from the old route.
**How to apply:** When a route change doesn't seem to take effect, suggest cache clear first before code changes.
