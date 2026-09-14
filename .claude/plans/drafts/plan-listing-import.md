# Plan: Listing Import (StreetEasy + General URL)

**Created:** 2026-09-14
**Status:** Draft
**Branch:** `listing-import`

## Problem

Listings are created manually — agents type in address, price, beds,
baths, sqft, upload photos one by one. NYC brokerages already have
their listings on StreetEasy, Zillow, and their own websites. Import
should be "paste a URL, confirm, done."

## Approach

Rather than building a fragile scraper for one site, use a two-layer
strategy:

1. **Structured data extraction** — Most real estate listing pages
   embed JSON-LD (`@type: RealEstateListing` or `Product`) or Open
   Graph meta tags. Parse these first — they're standardized and
   reliable.

2. **Site-specific parsers** — For StreetEasy and other major sites,
   add targeted parsers that extract data from known HTML structures.
   These are fragile but get more data (photos, floor plans) than
   structured data alone.

This way the import works on *any* listing URL that has structured
data, with enhanced support for specific sites.

## Design

### User Flow

1. User clicks "Import from URL" on the new listing page
2. Pastes a URL (e.g., `https://streeteasy.com/building/.../`)
3. System fetches the page, extracts data
4. Pre-fills the listing form with extracted data
5. User reviews, edits if needed, saves
6. Photos are attached from extracted image URLs

### Service Object

```
Listings::ImportService
  .call(url:)
  → { address:, price:, beds:, baths:, sqft:, description:,
      property_type:, listing_type:, photo_urls: [], source_url: }
```

Returns a plain hash of listing attributes. The controller builds
a `Listing` from it and renders the form pre-filled. Photos are
downloaded and attached on save (not on import preview).

### Extraction Layers

**Layer 1: Structured data (JSON-LD / Open Graph)**

```ruby
Listings::Extractors::StructuredData
```

- Parse `<script type="application/ld+json">` for RealEstateListing,
  Product, or Residence schema types
- Fall back to Open Graph meta tags (`og:title`, `og:image`, etc.)
- Works on any site that follows Schema.org conventions

**Layer 2: Site-specific parsers**

```ruby
Listings::Extractors::StreetEasy
Listings::Extractors::Zillow      # future
Listings::Extractors::Realtor     # future
```

- Pattern-match the URL hostname to select the parser
- Extract from known CSS selectors / HTML structure
- More data than structured data (floor plans, unit details)
- Fragile — will break when the site redesigns

### Parser Selection

```ruby
def parser_for(url)
  case URI.parse(url).host
  when /streeteasy\.com/ then Extractors::StreetEasy
  when /zillow\.com/     then Extractors::Zillow
  else                        Extractors::StructuredData
  end
end
```

Try the site-specific parser first, fall back to structured data
if it fails or returns incomplete results.

### Photo Handling

Import preview shows photo thumbnails from the extracted URLs.
On form submit, photos are downloaded and attached via
ActiveStorage. This avoids downloading photos for imports that
are abandoned.

```ruby
# In the create action, after listing.save:
import_params[:photo_urls].each do |url|
  listing.photos.attach(
    io: URI.open(url),
    filename: File.basename(URI.parse(url).path)
  )
end
```

Use a background job for photo downloads to avoid blocking the
request if there are many photos.

### Source Tracking

Add a `source_url` column to `listings` to track where the listing
was imported from. Useful for:
- Showing "Imported from StreetEasy" in the UI
- Re-importing / refreshing data later
- Deduplication (don't import the same listing twice)

## StreetEasy Specifics

StreetEasy listing pages include JSON-LD structured data with:
- `@type: Product` (price, name)
- Address in the breadcrumb and page title
- Photos in an image carousel
- Specs (beds, baths, sqft) in a details section

They also have meta tags:
- `og:title` — "2 BR Co-op at 350 Fifth Ave"
- `og:image` — primary photo URL
- `og:description` — listing description

The site-specific parser can extract:
- All carousel photo URLs (not just the OG image)
- Floor plan images (separate section)
- Unit/building amenities
- Open house schedule

### Legal Considerations

- StreetEasy TOS prohibits automated scraping
- However, we're fetching a single publicly-accessible page on
  behalf of a user who already has the listing (it's their listing)
- This is more "paste URL to auto-fill" than "scrape the site"
- Similar to how Slack unfurls URLs or how LinkedIn imports profiles
- Risk: StreetEasy could block requests. Mitigation: use a standard
  browser user agent, rate limit, cache responses

## Execution

### Step 1 — source_url column (TDD)
- **RED:** Model spec for `source_url` on Listing
- **GREEN:** Migration adding `source_url` string column to listings

### Step 2 — StructuredData extractor (TDD)
- **RED:** Unit specs with fixture HTML containing JSON-LD and OG tags
- **GREEN:** `Listings::Extractors::StructuredData` parses JSON-LD
  and OG meta tags, returns normalized hash

### Step 3 — StreetEasy extractor (TDD)
- **RED:** Unit specs with fixture HTML from a StreetEasy listing page
- **GREEN:** `Listings::Extractors::StreetEasy` parses known selectors,
  falls back to StructuredData for missing fields

### Step 4 — ImportService (TDD)
- **RED:** Specs for `Listings::ImportService.call(url:)` — URL
  fetching, parser selection, error handling (invalid URL, fetch
  failure, no data found)
- **GREEN:** Service fetches page, selects parser, returns attribute hash

### Step 5 — Controller + UI
- Add "Import from URL" button on listings/new
- `POST /listings/import_preview` — accepts URL, returns pre-filled form
- Form shows extracted data with edit capability
- Photo thumbnails shown as preview, downloaded on save

### Step 6 — Photo download job
- `Listings::PhotoImportJob` — downloads and attaches photos
  from URLs after listing is saved
- Runs in background via Solid Queue

### Step 7 — Ship
- `make lint`, `make test`
- Push, create PR

## Out of Scope

- Zillow / Realtor.com parsers (add later using same pattern)
- Automatic re-sync / refresh from source URL
- Bulk import (multiple listings at once)
- MLS/RETS integration (enterprise feature, different architecture)
