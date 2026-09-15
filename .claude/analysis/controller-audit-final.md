# Analysis: Controller Audit — Final Status

## Score: 3.5 → 5.0 (Complete)

All 10 categories at 5/5 after PRs #60, #61, #62.

---

## What's Left (Not Audit Failures — Future Improvements)

These are architectural decisions and enhancements, not gaps
against the audit checklist. None block a 5/5 score.

### 1. BrandAd Architecture

**Status:** Deferred design decision

BrandAd is a delegated type with zero additional fields. It exists
only to satisfy the `adable` polymorphism. The `Ads::BaseController`
handles it cleanly (9 lines), but the model is empty.

**Options:**
- Keep as-is (works, not broken)
- Remove delegated type, use `ad_type` enum on Ad directly
- Wait until brand ads gain features (sponsor logo, CTA URL)

**Recommendation:** Revisit when brand ads get requirements.

### 2. Invites Controller Complexity

**Status:** Works but complex

`InvitesController` has the most branching logic in the app — it
handles: new invite, accept as existing user, accept as new user,
expired invites, resend. Each path has different auth requirements.

**Not an audit failure** — the logic is correct and tested. But
if invites gain more flows (multi-account, role changes), consider
extracting to an `AcceptInvite` service.

### 3. Administrate N+1 / Counter Cache

**Status:** Safelisted in Bullet

Administrate's index pages trigger counter cache suggestions
(`Account => [:sites, :listings, :ads]`). These are Administrate's
internal queries — we can't add `includes` without forking the gem.

**Options:**
- Add `counter_cache: true` to `belongs_to` declarations (proper fix)
- Keep safelisted (current approach)

**Recommendation:** Add counter caches when admin performance matters
(100+ accounts). Low priority for < 50 accounts.

### 4. Polymorphic N+1 on ListingAd => Listing

**Status:** Safelisted in Bullet

When rendering listing ads, `listing_ad.listing` is lazy loaded.
Rails can't deeply eager load through polymorphic `delegated_type`
associations (`ad.adable.listing`). The alternative is a manual
preload query.

**Impact:** One extra query per unique listing ad in a playlist.
For playlists with 4-8 ads, this is 4-8 queries — acceptable.

**Fix when:** Playlists regularly exceed 20 ads and render time
is noticeable.

### 5. Alert Flash Messages Still Hardcoded

**Status:** Intentional

Notice messages use `t(".success")`. Alert messages remain hardcoded:

```ruby
flash[:alert] = result.error       # Dynamic from service
alert: "Try again later."          # Rate limit response
alert: "Passwords did not match."  # Specific error context
```

These are intentionally not I18n'd because:
- Service error messages are dynamic (from `PairPlayerToScreen`, etc.)
- Rate limit and password messages are context-specific
- No localization requirement exists

**Convert when:** The app needs multi-language support.

### 6. `unpair_player!` Still on Screen Model

**Status:** Intentional

`pair_player!` was moved to `PairPlayerToScreen` service, but
`unpair_player!` remains on the Screen model. It's a one-liner
that delegates to `ScreenPlayer#unpair!` — not enough logic to
justify a service.

**Extract when:** Unpairing gains side effects beyond deactivating
the ScreenPlayer (e.g., device wipe, notification, analytics event).

### 7. DashboardPresenter Not Tested

**Status:** Gap

`DashboardPresenter` was extracted but has no dedicated spec. The
dashboard request spec covers it implicitly (renders without error),
but the individual query methods are untested.

**Fix:** Add `spec/presenters/dashboard_presenter_spec.rb` with
specs for each method. Low urgency since the queries are simple
delegations to existing scopes.

### 8. Strict Loading Not Enabled

**Status:** Deferred

The plan included `config.active_record.strict_loading_by_default = true`
in development. This was not enabled because Bullet already catches
N+1s in both dev and test. Strict loading is more aggressive — it
raises on ANY lazy load, even intentional ones (e.g., accessing
`listing.agents` in a show view where you only have one listing).

**Enable when:** Bullet safelists are stable and the team wants
stricter enforcement. Will require adding `.strict_loading(false)`
to intentional lazy loads.

---

## Service Object Inventory

| Service | Lines | Spec | Status |
|---------|:-----:|:----:|--------|
| `AssignScreenContent` | 12 | Yes | Complete |
| `PairPlayerToScreen` | 30 | Yes | Complete |
| `CaptureLead` | 25 | Yes | Complete |

All three services are tested and used by their respective controllers.

## Standards Inventory

| Standard | File | Status |
|----------|------|--------|
| Controllers | `.claude/standards/controllers/conventions.md` | Complete |
| Database | `.claude/standards/database/migrations.md` | Existing |
| Testing | `.claude/standards/testing/tdd.md` | Existing |
| Code Org | `.claude/standards/code-organization/patterns.md` | Existing |
| Error Handling | `.claude/standards/error-handling/conventions.md` | Existing |

---

## Summary

The controller audit is complete. The codebase went from 3.5/5 to
5.0/5 across 3 PRs, 25+ commits, and ~50 files changed. The
remaining items are architectural preferences and future
improvements, not compliance gaps.
