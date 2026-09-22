# Plan v2: Live Ad Builder Preview

**Updated:** 2026-09-21
**Status:** Draft

## Problem

The ad form has a two-column layout: preview on the left, form
fields on the right. Currently:

- **Before save:** Preview is a placeholder with Stimulus text-swap
  for headline/body only. No layout, no theme, no image, no listing
  data. User can't see what the ad will look like until they save.
- **After save:** Preview renders the real layout partial. But to
  iterate on appearance, user must save → see result → edit → save
  → see result. Slow loop.

The goal: **real-time preview of the actual ad layout** as the user
builds it. Change layout → preview updates. Change theme → colors
swap. Pick a listing → listing data appears in the preview.

Desktop only — the two-column layout collapses on mobile, making
live preview pointless since you can't see both simultaneously.

## Approach: Turbo Stream with Server-Side Rendering

The preview is a Turbo Frame that re-renders the real layout partial
on each meaningful form change. The server has all the context
(listing data, agent, image) that the client doesn't.

**Why server-side, not client-side?**
- Ad layouts use ERB helpers (`number_to_currency`, `image_tag`,
  `ad_theme_style`), ActiveStorage variants, and model methods
  (`listing.primary_agent`, `listing_ad.badge_label`)
- Replicating in JS means two rendering stacks
- Server render is one `render partial:` call — already works

---

## Implementation

### 1. Preview endpoint on Ads::BaseController

Build the ad from form params without saving, render the layout:

```ruby
def preview
  set_adable(adable_class.new(adable_params))
  @ad = @adable.build_ad(ad_params.merge(account: Current.account).merge(ad_defaults))
  @ad.apply_defaults
  authorize! @ad

  respond_to do |format|
    format.turbo_stream {
      render turbo_stream: turbo_stream.replace(
        "ad_preview",
        partial: "app/ads/shared/preview_canvas",
        locals: { ad: @ad }
      )
    }
  end
end
```

### 2. Route

```ruby
namespace :ads do
  resources :listing_ads, only: %i[new create edit update] do
    collection { post :preview }
  end
  # same for agent_ads, brand_ads, collection_ads
end
```

`POST` collection route — form data is sent, ad doesn't exist yet.

### 3. Turbo Frame in the form

```erb
<%= turbo_frame_tag "ad_preview" do %>
  <%= render "app/ads/shared/preview_canvas", ad: @ad %>
<% end %>
```

### 4. Stimulus controller

```javascript
// ad_builder_controller.js
export default class extends Controller {
  static targets = ["form"]
  static values = { previewUrl: String }

  connect() {
    this.timeout = null
  }

  // Select/radio change — immediate
  changed() {
    this.submitPreview()
  }

  // Text input — debounced 300ms
  typed() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => this.submitPreview(), 300)
  }

  submitPreview() {
    const formData = new FormData(this.formTarget)

    fetch(this.previewUrlValue, {
      method: "POST",
      body: formData,
      headers: {
        "Accept": "text/vnd.turbo-stream.html",
        "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
      }
    })
    .then(r => r.text())
    .then(html => Turbo.renderStreamMessage(html))
  }
}
```

### 5. Form field wiring

| Field | Trigger | Action |
|-------|---------|--------|
| Layout (radio) | Immediate | `change->ad-builder#changed` |
| Theme (radio) | Immediate | `change->ad-builder#changed` |
| Listing (select) | Immediate | `change->ad-builder#changed` |
| Badge (radio) | Immediate | `change->ad-builder#changed` |
| Headline (text) | Debounced 300ms | `input->ad-builder#typed` |
| Body (textarea) | Debounced 300ms | `input->ad-builder#typed` |
| Image (file) | Not in v1 | Placeholder until saved |

### 6. Preview canvas update

Currently renders only if `ad.persisted?`. Change to render if
the ad has enough data:

```erb
<% can_preview = ad.layout.present? && ad.adable.present? %>
<% if can_preview && (ad.adable.respond_to?(:listing) ? ad.adable.listing.present? : true) %>
  <%= render "app/ads/layouts/#{ad.layout}", ad: ad %>
<% else %>
  <%# placeholder %>
<% end %>
```

Listing ads need a listing selected. Brand ads just need a headline.

---

## Build Order (TDD)

### Step 1 — Preview route + endpoint

**File:** `config/routes.rb`

Add preview collection route to each ad type:

```ruby
namespace :ads do
  resources :listing_ads, only: %i[new create edit update] do
    collection { post :preview }
  end
  resources :collection_ads, only: %i[new create edit update] do
    collection { post :preview }
  end
  resources :agent_ads, only: %i[new create edit update] do
    collection { post :preview }
  end
  resources :brand_ads, only: %i[new create edit update] do
    collection { post :preview }
  end
end
```

**File:** `app/controllers/app/ads/base_controller.rb`

Add `preview` action:

```ruby
def preview
  set_adable(adable_class.new(adable_params))
  @ad = @adable.build_ad(ad_params.merge(account: Current.account).merge(ad_defaults))
  @ad.apply_defaults
  authorize! @ad

  respond_to do |format|
    format.turbo_stream {
      render turbo_stream: turbo_stream.replace(
        "ad_preview",
        partial: "app/ads/shared/preview_canvas",
        locals: { ad: @ad }
      )
    }
  end
end
```

**RED:** `spec/requests/ads/listing_ads_spec.rb`

```ruby
describe "POST /ads/listing_ads/preview" do
  it "returns a turbo stream with the preview" do
    listing = create(:listing, account: account)
    post preview_ads_listing_ads_path, params: {
      listing_ad: { listing_id: listing.id, badge: "just_listed" },
      ad: { headline: "Test", layout: "hero", theme: "dark" }
    }, as: :turbo_stream

    expect(response).to be_successful
    expect(response.body).to include("turbo-stream")
    expect(response.body).to include("ad_preview")
  end

  it "renders the ad layout in the preview" do
    listing = create(:listing, account: account)
    post preview_ads_listing_ads_path, params: {
      listing_ad: { listing_id: listing.id, badge: "just_listed" },
      ad: { headline: "Beautiful Home", layout: "hero", theme: "dark" }
    }, as: :turbo_stream

    expect(response.body).to include("ad-canvas")
    expect(response.body).to include("Beautiful Home")
  end

  it "renders placeholder when listing not selected" do
    post preview_ads_listing_ads_path, params: {
      listing_ad: { badge: "just_listed" },
      ad: { headline: "Test", layout: "hero", theme: "dark" }
    }, as: :turbo_stream

    expect(response).to be_successful
    expect(response.body).to include("Preview will appear")
  end
end
```

**GREEN:** Implement the route + controller action.

```
COMMIT: "Step 1: Add preview endpoint to Ads::BaseController"
```

---

### Step 2 — Update preview canvas for unsaved ads

**File:** `app/views/app/ads/shared/_preview_canvas.html.erb`

Change the render condition from "is it persisted?" to "does it
have enough data to render?":

```erb
<% can_preview = ad.layout.present? && ad.adable.present? &&
     (ad.adable.respond_to?(:listing) ? ad.adable.listing.present? : true) %>
```

Listing ads require a listing. Agent ads require an agent. Brand
ads just need a headline. Collection ads need a title.

**RED:** Add spec for unsaved ad rendering in preview request spec.

**GREEN:** Update the partial.

```
COMMIT: "Step 2: Preview canvas renders unsaved ads with sufficient data"
```

---

### Step 3 — Stimulus controller

**New file:** `app/javascript/controllers/ad_builder_controller.js`

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form"]
  static values = { previewUrl: String }

  connect() {
    this.timeout = null
  }

  changed() {
    this.submitPreview()
  }

  typed() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => this.submitPreview(), 300)
  }

  submitPreview() {
    const formData = new FormData(this.formTarget)

    fetch(this.previewUrlValue, {
      method: "POST",
      body: formData,
      headers: {
        "Accept": "text/vnd.turbo-stream.html",
        "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
      }
    })
    .then(r => r.text())
    .then(html => Turbo.renderStreamMessage(html))
  }
}
```

```
COMMIT: "Step 3: Add ad_builder Stimulus controller"
```

---

### Step 4 — Wire up form views

**File:** `app/views/app/ads/listing_ads/_form.html.erb`

Wrap the form with the ad-builder controller and turbo frame:

```erb
<div data-controller="ad-builder"
     data-ad-builder-preview-url-value="<%= preview_ads_listing_ads_path %>">

  <%= form_with model: @ad, url: ...,
      data: { ad_builder_target: "form" } do |form| %>

    <div class="grid grid-cols-1 lg:grid-cols-[1fr_380px] gap-6">
      <%# Left — Live preview in turbo frame %>
      <div>
        <%= turbo_frame_tag "ad_preview" do %>
          <%= render "app/ads/shared/preview_canvas", ad: @ad %>
        <% end %>
      </div>

      <%# Right — Form fields with data-actions %>
      <div class="flex flex-col gap-5">
        ...
      </div>
    </div>
  <% end %>
</div>
```

Add `data-action` attributes to form fields:

**Files to update:**
- `app/views/app/ads/listing_ads/_form.html.erb` — badge radios,
  listing select, headline, body
- `app/views/app/ads/shared/_appearance_fields.html.erb` — layout
  radios, theme radios
- `app/views/app/ads/shared/_content_fields.html.erb` — headline
  input, body textarea

| Field partial | Element | Action |
|--------------|---------|--------|
| `_form.html.erb` (listing_ads) | Badge radios | `change->ad-builder#changed` |
| `_form.html.erb` (listing_ads) | Listing select | `change->ad-builder#changed` |
| `_appearance_fields.html.erb` | Layout radios | `change->ad-builder#changed` |
| `_appearance_fields.html.erb` | Theme radios | `change->ad-builder#changed` |
| `_content_fields.html.erb` | Headline input | `input->ad-builder#typed` |
| `_content_fields.html.erb` | Body textarea | `input->ad-builder#typed` |

Repeat for `agent_ads/_form`, `brand_ads/_form`, `collection_ads/_form`
(each wraps with the controller, uses their own preview URL).

```
COMMIT: "Step 4: Wire ad forms with ad-builder controller and turbo frame"
```

---

### Step 5 — Remove old ad_preview_controller

**Delete:** `app/javascript/controllers/ad_preview_controller.js`

The old Stimulus controller that did text-only swaps is replaced
by the full server-rendered preview via ad_builder_controller.

Remove `data-controller="ad-preview"` and related targets from
form views.

```
COMMIT: "Step 5: Remove old ad_preview Stimulus controller"
```

---

## Verification

1. `make test` — green after each step
2. `make lint` — clean
3. **New listing ad:** select listing → preview shows real layout
   with price, address, specs, agent strip
4. **Change layout:** hero → split → minimal → preview re-renders
5. **Change theme:** dark → light → brand → colors swap in preview
6. **Change badge:** just_listed → open_house → badge label updates
7. **Type headline:** text appears in preview after 300ms pause
8. **Brand ad:** just type headline → preview renders immediately
9. **Edit existing ad:** preview shows current state, updates on change
10. **Mobile:** form stacks vertically, preview above form, no
    live updating (no JS errors either)

---

## Files Changed

| File | Change |
|------|--------|
| `config/routes.rb` | Add preview collection route to 4 ad type resources |
| `app/controllers/app/ads/base_controller.rb` | Add `preview` action |
| `app/views/app/ads/shared/_preview_canvas.html.erb` | Render unsaved ads with sufficient data |
| `app/javascript/controllers/ad_builder_controller.js` | New Stimulus controller |
| `app/views/app/ads/listing_ads/_form.html.erb` | Wrap with controller, turbo frame, data-actions |
| `app/views/app/ads/agent_ads/_form.html.erb` | Same |
| `app/views/app/ads/brand_ads/_form.html.erb` | Same |
| `app/views/app/ads/collection_ads/_form.html.erb` | Same |
| `app/views/app/ads/shared/_appearance_fields.html.erb` | Add data-actions to layout/theme radios |
| `app/views/app/ads/shared/_content_fields.html.erb` | Add data-actions to headline/body inputs |
| `app/javascript/controllers/ad_preview_controller.js` | Delete (replaced) |
| `spec/requests/ads/listing_ads_spec.rb` | Add preview endpoint specs |

---

## Out of Scope (v1)

- Image live preview (placeholder until saved)
- Mobile live preview
- Preview at different screen sizes
- Undo/redo
- Animation/transition preview
