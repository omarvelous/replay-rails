# Plan: Mailer Overhaul

**Created:** 2026-09-25
**Status:** Draft
**Branch:** `feature/mailer-overhaul`

## Problem

The mailer system has accumulated debt since the initial build:

1. **`from@example.com`** — default sender is a placeholder; nothing delivers in prod
2. **3 of 4 mailers missing text templates** — spam filters penalize HTML-only emails
3. **No shared layout** — each view hand-rolls inline styles; inconsistent look
4. **Missing transactional emails** — no welcome, no invite-accepted, no password-changed
5. **Missing previews** — can't visually QA PasswordsMailer or InquiryMailer
6. **No CSS inlining** — manual `style=""` everywhere is fragile and hard to maintain

## Approach

### Shared branded layout + premailer-rails

Add `premailer-rails` gem. Write email styles once in a `<style>` block
in `mailer.html.erb` — premailer auto-inlines them at send time. This
eliminates all hand-rolled `style=""` attributes and gives every email
a consistent branded look.

Layout structure (600px single-column, 2026 email best practice):

```
┌──────────────────────────────────┐
│  Logo (text or image)            │
├──────────────────────────────────┤
│                                  │
│  Content (yield)                 │
│                                  │
├──────────────────────────────────┤
│  Footer: RePlay · Unsubscribe    │
│  (small, muted)                  │
└──────────────────────────────────┘
```

- Max width 600px, centered
- System font stack (no web fonts in email)
- Light background (#f9fafb), white content card
- Indigo-600 (#4f46e5) for CTAs
- Dark text (#111827) for headings, medium (#374151) for body

### Text templates for every email

Every `.html.erb` gets a matching `.text.erb`. Plain text, no styling,
just information. This is a deliverability and accessibility requirement.

### Fix the sender

```ruby
# application_mailer.rb
default from: "RePlay <notifications@replaytv.co>"
```

Per-mailer overrides where appropriate:
- InquiryMailer → `from: "RePlay <hello@replaytv.co>"`
- LeadMailer → could use account-specific reply-to in the future

### New mailers

| Mailer | Method | Trigger | Recipient |
|--------|--------|---------|-----------|
| AccountMailer | `welcome(user, account)` | After first user signs up (not invites) | The user |
| InviteMailer | `accepted(invite)` | After invite is accepted | The inviter |
| PasswordsMailer | `changed(user)` | After password is changed | The user |

**Welcome email** — Sent on account creation. Short: "Welcome to RePlay.
Here's what to do first: 1. Add a listing. 2. Create an ad. 3. Set up a
screen." Links to docs.

**Invite accepted** — "Omar accepted your invite and joined as Agent."
One-liner with a link to the team page. The inviter should know.

**Password changed** — Security notification. "Your password was just
changed. If this wasn't you, contact support." No CTA, just awareness.

### Complete previews

Add ActionMailer::Preview classes for every mailer method:
- `PasswordsMailerPreview#reset`
- `InquiryMailerPreview#notification`
- `AccountMailerPreview#welcome`
- `InviteMailerPreview#accepted`
- `PasswordsMailerPreview#changed`

### Spec coverage

Every mailer method gets a spec covering:
- Correct recipient
- Subject line content
- Key content in HTML body
- Key content in text body
- Ahoy tracking where applicable

## Design Decisions

**Why premailer-rails over other approaches:**
- Zero config — just add the gem; it hooks into ActionMailer automatically
- Writes styles in `<style>` block, auto-inlined at delivery time
- Works with the existing mailer layout pattern
- No build step, no asset pipeline dependency
- Battle-tested (500M+ downloads)

**Why not MJML or React Email:**
- Adds a compilation step and JS dependency to a pure-Ruby stack
- premailer + well-structured HTML tables achieve the same result
- MJML is great for teams with dedicated email designers; we don't need it

**Why text templates matter in 2026:**
- Gmail clips HTML-only emails over 102KB
- Apple Mail privacy features can block HTML tracking pixels
- Screen readers and accessibility tools prefer text
- Some corporate email filters outright reject HTML-only
- `multipart/alternative` (HTML + text) is the deliverability standard

## Execution

### Phase 1 — Foundation

```
1. Add premailer-rails gem
   COMMIT

2. RED:  Spec for ApplicationMailer default from address
   GREEN: Fix from address to "RePlay <notifications@replaytv.co>"
   COMMIT

3. Build shared mailer.html.erb layout with branded styles
   Build shared mailer.text.erb layout
   COMMIT

4. Strip inline styles from all 4 existing HTML templates
   (premailer handles inlining now)
   COMMIT
```

### Phase 2 — Text templates

```
5. RED:  Specs asserting text body content for InviteMailer
   GREEN: Add invite.text.erb
   COMMIT

6. RED:  Specs asserting text body content for LeadMailer
   GREEN: Add new_lead.text.erb
   COMMIT

7. RED:  Specs asserting text body content for InquiryMailer
   GREEN: Add notification.text.erb
   COMMIT

8. RED:  Specs asserting text body content for PasswordsMailer
   GREEN: Verify reset.text.erb (already exists)
   COMMIT
```

### Phase 3 — New mailers

```
9.  RED:  AccountMailer#welcome spec
    GREEN: AccountMailer + welcome.html.erb + welcome.text.erb
    Wire up in registrations controller (after account creation)
    COMMIT

10. RED:  InviteMailer#accepted spec
    GREEN: accepted.html.erb + accepted.text.erb
    Wire up in Invites::RegistrationsController#create
    COMMIT

11. RED:  PasswordsMailer#changed spec
    GREEN: changed.html.erb + changed.text.erb
    Wire up in PasswordsController#update
    COMMIT
```

### Phase 4 — Previews + polish

```
12. Add ActionMailer::Preview for every mailer method (7 total)
    COMMIT

13. make lint, make test — verify all green
    COMMIT
```

## Out of Scope

- Notification preferences / unsubscribe (Tier 2 Notifications feature)
- Account-specific reply-to addresses
- Custom email templates per account (white-label feature)
- Bounce/complaint handling (needs SES/Postmark integration)
- Email queue monitoring dashboard

## Verification

1. `make test` — green, all mailer specs pass
2. `make lint` — no offenses
3. Visit `/rails/mailers` in dev — all previews render correctly
4. Check HTML emails in letter_opener — branded layout, consistent look
5. Check text emails in letter_opener — clean plaintext, all info present
6. Verify premailer inlines styles (inspect delivered HTML source)
