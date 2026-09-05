# Plan: Marketing Site Overhaul for NYC Launch

## Context

The current marketing site is a skeleton — four pages (home, features,
pricing, about) with placeholder headlines and no real content. The
site needs to serve the NYC hyper-local strategy where:

- Deals close in person, not through the website
- The site is a credibility check after a demo, not a conversion engine
- Two product motions: storefront window displays + portable open house
- Buyers are independent NYC brokerages and individual agents
- No MLS sync messaging (irrelevant in NYC)

See: `.claude/analysis/nyc-go-to-market.md`,
`.claude/analysis/landing-page.md`

---

## Current State

| Page | What exists |
|------|-------------|
| Home | One headline ("Your window, working 24/7"), one subhead, no CTA buttons, no sections |
| Features | Headline + one-line subhead, no feature content |
| Pricing | Headline + one-line subhead, no pricing tiers |
| About | Headline + one-line subhead, no content |
| Layout | Nav (Features, Pricing, About, Log in, Start free trial) + minimal footer |

All pages use the `marketing` layout with the same nav and footer.

---

## Site Purpose (NYC Strategy)

The website serves three roles:

1. **Credibility check** — after an in-person demo, the prospect
   Googles RePlay. The site confirms what they heard and looks
   professional.

2. **Warm lead self-service** — "My friend at ABC Realty told me
   about you." They should see both products, pricing, and be able
   to book a demo or start a trial.

3. **Open house product page** — agents who saw the portable screen
   need a page explaining what they saw and how to get it.

---

## Page Plan

### Home (Landing Page)

**Goal:** Communicate both product motions clearly. Primary CTA is
"Book a demo" (NYC deals close in person). Secondary is "Start free
trial" for warm leads.

#### Section 1: Hero

```
Headline:  "Your storefront, always on"
Subhead:   "Dynamic window displays and interactive open house
            signage for NYC brokerages. No more printed cards.
            No more stale listings."
CTA:       [Book a demo]  (primary)
           "or start a free trial" (text link)
Visual:    Product screenshot — storefront window with listings on
           a screen, NYC street context
```

NYC-specific: subtle signal like "Built for NYC brokerages" or a
neighborhood reference. Don't over-index on NYC in the hero — keep
it adaptable for future markets.

#### Section 2: Two Products

Side-by-side cards or stacked sections introducing both motions:

**Window Displays**
- Icon/illustration of a brokerage storefront
- "Your listings on screen, always current"
- "Replace printed window cards with a dynamic display. Update from
  your phone. Capture walk-in leads with QR codes."
- [Learn more →] (anchor to features section or dedicated page)

**Open House Signage**
- Icon/illustration of portable screen at an open house
- "Turn every open house into an interactive experience"
- "Visitors browse photos, floor plans, and property details on a
  touch screen. Leads captured before they leave the building."
- [Learn more →]

#### Section 3: How It Works

Three steps, simple:

1. **Add your listings** — "Upload photos, enter details. Takes
   2 minutes per listing."
2. **Choose your format** — "Build a window display playlist or
   create an interactive open house experience."
3. **Go live** — "Assign to a screen. Content appears instantly.
   Update anytime from your phone."

#### Section 4: Features Grid

6 features, 2x3 grid. Icon + headline + one-liner each:

1. **Dynamic listings** — "Photos, price, and details — always current"
2. **QR lead capture** — "Walk-by scans become leads in your inbox"
3. **Agent branding** — "Your photo, name, and contact on every ad"
4. **Interactive touch** — "Swipe through photos and floor plans"
5. **Manage from your phone** — "Update listings without touching a computer"
6. **Multiple screens** — "Window, lobby, open house — one dashboard"

#### Section 5: Social Proof

Early stage — options depending on what's available:

- **Pre-launch:** "Built by real estate technologists in NYC" +
  product screenshots showing real listing data
- **Early customers:** Named testimonial with photo and brokerage
  name. One quote is enough if it's specific.
- **Metrics:** "X listings displayed · Y leads captured" (real
  internal numbers, even if small)

#### Section 6: Pricing Preview

Teaser, not full pricing page:

```
Simple, transparent pricing

Window Display    $99/mo per screen
Open House Kit    $49/mo per agent
Brokerage Bundle  Custom — talk to us

[See full pricing →]    [Book a demo]
```

#### Section 7: Final CTA

```
"Ready to upgrade your storefront?"
[Book a demo]
"No commitment. We'll bring the screen."
```

---

### Features Page

Expanded versions of the features grid with product screenshots.
Organized by product motion:

**For Your Storefront**
- Listing ad builder (screenshot of ad creator)
- Playlist management (screenshot of playlist editor)
- QR code lead capture (screenshot of QR on ad + lead inbox)
- Real-time updates (screenshot of phone → screen update)

**For Open Houses**
- Interactive experience builder (screenshot of experience config)
- Touch-screen photo gallery (screenshot of kiosk view)
- On-screen lead capture (screenshot of lead form on kiosk)
- Agent branding (screenshot of agent card on screen)

**For Your Business**
- Lead inbox with status tracking
- Multi-screen management
- Analytics dashboard (impressions, scans, leads)
- Team management and roles

---

### Pricing Page

Full pricing with feature comparison:

| | Window Display | Open House Kit | Brokerage Bundle |
|---|---|---|---|
| Price | $99/mo per screen | $49/mo per agent | Custom |
| Screens | 1 | 1 portable | 3+ |
| Listings | Unlimited | Unlimited | Unlimited |
| QR lead capture | ✓ | ✓ | ✓ |
| Interactive touch | — | ✓ | ✓ |
| Agent branding | ✓ | ✓ | ✓ |
| Analytics | ✓ | ✓ | ✓ |
| Dedicated setup | — | — | ✓ |

CTA per tier:
- Window Display → "Start free trial"
- Open House Kit → "Start free trial"
- Brokerage Bundle → "Book a demo"

FAQ section below pricing (common objections):
- "Do I need to buy a screen?"
- "How long does setup take?"
- "Can I cancel anytime?"
- "Do you install the screen?"

---

### About Page

Short, trust-building:

- Who we are (1-2 paragraphs — NYC-based, real estate tech)
- Why we built this (the pain of printed window cards)
- Photo of founder/team (if available)
- Contact info (email, phone)
- Office location or "Based in NYC" signal

---

## Layout Changes

### Navigation

Current: Features | Pricing | About | Log in | Start free trial

Updated:
- Add "Book a demo" as primary CTA (indigo button)
- Demote "Start free trial" to secondary (outline or text link)
- Keep Features, Pricing, About
- Add mobile hamburger menu (currently `hidden md:flex` with
  no mobile fallback)

### Footer

Current: Logo + copyright only.

Updated:
- Column 1: Logo + one-liner
- Column 2: Product links (Window Displays, Open Houses, Pricing)
- Column 3: Company links (About, Contact, Docs)
- Column 4: "Book a demo" CTA + email address
- Bottom: copyright + privacy/terms links

---

## "Book a Demo" Flow

Primary CTA throughout the site. Options:

**A — Calendly/Cal.com embed** — visitor picks a time, you show up
with a screen. Lowest friction.

**B — Simple form** — name, email, phone, brokerage name, message.
Creates a lead internally or sends an email. More control.

**C — mailto link** — simplest possible. Works for low volume.

**Recommendation:** Start with **B** (simple form). Build a
`/demo` page with a form that emails you. Upgrade to Calendly
when volume warrants it.

### Demo Request Page (`/demo`)

```
Book a demo

We'll bring a screen to your office and show you RePlay in action.
15 minutes, no commitment.

[Name]
[Email]
[Phone]
[Brokerage name]
[Message (optional)]

[Request demo]
```

---

## Routes

```ruby
# Add to marketing scope
get "/demo", to: "pages#demo", as: :demo
post "/demo", to: "demo_requests#create", as: :demo_requests
```

Or keep it simpler — the demo page is just a static page with a
mailto or Calendly embed, no backend needed initially.

---

## Build Order

### Phase 0: Theme prototyping (1 day) — COMPLETE

Build the home page once with full content (all sections from the
home page plan above). Add a floating theme switcher that toggles
between three visual directions. Same markup and copy — only the
styling changes.

**Implementation:** CSS custom properties on `<html>` toggled by a
Stimulus controller. Each theme sets colors, typography, spacing,
card treatment, and hero style. The switcher is a floating pill in
the bottom-right corner, visible only on the marketing site.

**Three directions:**

1. **Clean/Minimal** — White backgrounds, generous whitespace, muted
   gray/indigo palette, thin 1px borders, system font stack at normal
   weight. Cards are flat with subtle ring. Hero is light with dark
   text. The "premium SaaS" look — Stripe, Linear, Vercel.

2. **Bold/Dark** — Dark hero section (gray-900/950), high-contrast
   white typography, indigo-to-teal gradient accents, glowing CTAs.
   Content sections alternate white and dark. Cards have deeper
   shadows. The "modern tech" look — Raycast, Arc, Framer.

3. **Warm/Editorial** — Off-white/cream base (stone-50), serif font
   for headings (e.g., DM Serif Display), warmer palette (amber,
   stone, warm gray), softer rounded corners, subtle paper-like
   texture. The "boutique real estate" look — feels premium and
   approachable to brokerages who aren't tech-forward.

**Deliverable:** One page at `/` with all content sections, a
floating toggle to switch themes, and a deploy to staging so the
theme decision can be made in a real browser on desktop and mobile.

**Decision gate:** Pick a direction (or hybrid) before proceeding
to Phase 1. All subsequent work uses the chosen theme.

### Phase 1: Home page polish (1-2 days) — COMPLETE
1. Lock in chosen theme, remove switcher
2. Refine section spacing and responsive breakpoints
3. Add placeholder product visuals (screenshots or mockups)
4. Wire up "Book a demo" CTA (anchor to demo section or page)

### Phase 2: Supporting pages (1-2 days) — COMPLETE
5. Features page with screenshots
6. Pricing page with comparison table + FAQ
7. About page with trust content
8. Demo request page (form or Calendly)

### Phase 3: Layout + polish (1 day) — COMPLETE
9. Nav update (Book a demo as primary CTA)
10. Mobile nav (hamburger menu)
11. Footer with columns
12. Meta tags (title, description, OG image per page)

### Phase 4: Content (ongoing)
13. Real product screenshots (needs the product running)
14. Testimonials as they come in
15. Blog or case studies (future)

---

## What This Plan Does NOT Cover

- SEO strategy or blog content
- Paid ads or landing page variants
- Email capture / newsletter
- Analytics / conversion tracking (Plausible, PostHog, etc.)
- Custom domain setup for marketing site
- Photography of the product in real NYC storefronts

---

## Dependencies

- **Product screenshots** — need realistic-looking screens with
  real listing data. Can use seed data or demo account.
- **Pricing validation** — tiers and prices are estimates from
  the NYC GTM analysis. May change after Phase 1 demos.
- **Demo request handling** — even a simple form needs somewhere
  to go (email, internal lead, or Calendly).
- **Experiences feature** — the open house product sections
  reference features that don't exist yet (see
  `plan-experiences-v2.md`). Marketing can describe the vision
  before the feature ships, but screenshots will need the real UI.

---

## Open Questions

1. **"Book a demo" vs "Get a demo"?** Small copy decision but sets
   the tone. "Book" implies a scheduled meeting. "Get" implies
   they receive something.

2. **How NYC-specific should the site be?** If we say "Built for
   NYC brokerages" on the home page, we limit ourselves when
   expanding. Could instead use NYC in the social proof / case
   studies without hard-coding it into the positioning.

3. **Pricing on the home page?** The analysis says pricing
   transparency builds trust. But if deals close in person,
   showing pricing might anchor too low. Could show "Starting at
   $49/mo" without the full breakdown.

4. **One home page or two landing pages?** Could have `/` as the
   main page and `/open-house` as a dedicated page for the agent
   product. Depends on whether one page can sell both motions
   without confusion.

---

## Inquiry Model (Demo Request Capture)

The demo form needs a backend to capture submissions. Rather than
reusing the tenant-scoped `Lead` model, introduce a general-purpose
`Inquiry` model with no account/tenant dependency.

### Model

```ruby
class Inquiry < ApplicationRecord
  TYPES = %w[demo_request general].freeze

  validates :name, presence: true
  validates :email, presence: true
  validates :inquiry_type, inclusion: { in: TYPES }
end
```

### Columns

- `name` (string, not null)
- `email` (string, not null)
- `phone` (string, nullable)
- `company` (string, nullable — brokerage name)
- `inquiry_type` (string, not null, default: "demo_request")
- `message` (text, nullable)
- `interest` (string, nullable — "window", "openhouse", "both", "other")
- `responded_at` (datetime, nullable — tracks follow-up)

### Controller

Public endpoint on the marketing site:

```ruby
# POST /inquiries
module Marketing
  class InquiriesController < BaseController
    def create
      @inquiry = Inquiry.new(inquiry_params)
      if @inquiry.save
        InquiryMailer.notification(@inquiry).deliver_later
        redirect_to demo_path, notice: "Thanks! We'll be in touch within 24 hours."
      else
        render "pages/demo", status: :unprocessable_content
      end
    end
  end
end
```

### Mailer

`InquiryMailer#notification` — sends form data to internal email
(e.g., hello@replaytv.co) so you get notified immediately.

### Admin

Add `Inquiry` to Administrate dashboard for viewing and tracking
responses.

### Routes

```ruby
# Marketing subdomain
scope module: "marketing" do
  resources :inquiries, only: :create
end
```

### Rate limiting

Protect the public endpoint with Rack::Attack (already configured
in the app for other public endpoints):

- Throttle `POST /inquiries` to 5 requests per IP per hour
- Honeypot field on the form (hidden input, reject if filled)
- Future: add reCAPTCHA or Turnstile if spam becomes an issue

### Build order (TDD) — COMPLETE

1. RED: Inquiry model spec (validations) ✓
2. GREEN: Migration + model + factory ✓
3. RED: Request spec (create, validation errors, honeypot) ✓
4. GREEN: Controller + route + Rack::Attack throttle ✓
5. Honeypot field on demo form ✓
6. Mailer (InquiryMailer#notification) ✓
7. Wire up demo form to POST /inquiries (scope: :inquiry) ✓
8. Admin dashboard (Administrate) ✓
9. Strip subdomain param from admin controllers ✓
10. Flash notice inside demo form card ✓
