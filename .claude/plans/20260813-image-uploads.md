# Plan: Image Uploads

## Current state
- ActiveStorage is configured (Disk service in dev/prod, test service in test)
- `image_processing ~> 1.2` gem is already in the Gemfile
- ActiveStorage migrations have NOT been run yet — `active_storage_blobs` table does not exist
- No models use `has_one_attached` or `has_many_attached` yet

---

## Scope

Two models get attachments:

| Model | Attachment | Cardinality | Purpose |
|-------|-----------|-------------|---------|
| `Ad` | `image` | one | Hero image shown in the ad creative |
| `Listing` | `photos` | many | Property photos; first photo used in ads |

---

## Step 1 — Run ActiveStorage migrations

```bash
make generate ARGS="active_storage:install"
make migrate
```

This creates `active_storage_blobs`, `active_storage_attachments`, and `active_storage_variant_records` tables.

---

## Step 2 — Attach to models

```ruby
# app/models/ad.rb
has_one_attached :image

# app/models/listing.rb
has_many_attached :photos
```

No additional migration needed — ActiveStorage uses its own polymorphic join tables.

---

## Step 3 — Validations

Use Rails built-in `validates` with `content_type` and `byte_size`:

```ruby
# app/models/ad.rb
validates :image, content_type: { in: %w[image/jpeg image/png image/webp], message: "must be a JPG, PNG, or WebP" },
                  size: { less_than: 10.megabytes, message: "must be under 10MB" },
                  if: -> { image.attached? }

# app/models/listing.rb
validates :photos, content_type: { in: %w[image/jpeg image/png image/webp] },
                   size: { less_than: 10.megabytes },
                   if: -> { photos.attached? }
```

---

## Step 4 — Variants

Define named variants on the models for consistent sizing everywhere:

```ruby
# app/models/ad.rb
has_one_attached :image do |attachable|
  attachable.variant :thumb,   resize_to_fill: [400, 225]   # card thumbnails
  attachable.variant :preview, resize_to_fill: [1920, 1080] # player full-screen
end

# app/models/listing.rb
has_many_attached :photos do |attachable|
  attachable.variant :thumb, resize_to_fill: [400, 225]
  attachable.variant :card,  resize_to_fill: [800, 450]
end
```

---

## Step 5 — Permit params

```ruby
# ads_controller.rb
params.require(:ad).permit(:headline, :body, :listing_id, :image)

# listings_controller.rb
params.require(:listing).permit(:address, :price, :beds, :baths, :sqft, :status, photos: [])
```

---

## Step 6 — Form UI

### Ad image upload (`ads/_form.html.erb`)

Add a styled file input below the canvas preview in the right panel:

```erb
<div class="rounded-lg bg-white shadow-sm ring-1 ring-gray-900/5 p-5">
  <h3 class="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-3">Image</h3>
  <% if ad.image.attached? %>
    <%= image_tag ad.image.variant(:thumb), class: "w-full rounded-lg object-cover mb-3" %>
  <% end %>
  <label class="flex flex-col items-center justify-center gap-2 rounded-lg border-2 border-dashed border-gray-300 px-6 py-8 cursor-pointer hover:border-indigo-400 hover:bg-indigo-50 transition-colors">
    <%= form.file_field :image, accept: "image/jpeg,image/png,image/webp", class: "sr-only" %>
    <svg class="size-8 text-gray-400" .../>
    <span class="text-sm text-gray-500">Click to upload or drag and drop</span>
    <span class="text-xs text-gray-400">JPG, PNG, WebP — max 10MB</span>
  </label>
</div>
```

### Listing photos (`listings/_form.html.erb`)

Multi-file input with existing photo thumbnails:

```erb
<% if listing.photos.any? %>
  <div class="flex flex-wrap gap-2 mb-3">
    <% listing.photos.each do |photo| %>
      <%= image_tag photo.variant(:thumb), class: "w-20 h-14 object-cover rounded" %>
    <% end %>
  </div>
<% end %>
<%= form.file_field :photos, multiple: true, accept: "image/jpeg,image/png,image/webp", class: "..." %>
```

Note: multi-file replace (not append) on each submit. Appending requires separate controller logic or direct upload UI.

---

## Step 7 — Display in views

### Ad show / preview

```erb
<% if @ad.image.attached? %>
  <%= image_tag @ad.image.variant(:preview), class: "absolute inset-0 w-full h-full object-cover" %>
<% end %>
```

### Ad card thumbnail (index / playlist timeline)

```erb
<% if ad.image.attached? %>
  <%= image_tag ad.image.variant(:thumb), class: "w-full h-full object-cover" %>
<% else %>
  <%# existing gradient fallback %>
<% end %>
```

### Listing show (photo gallery)

```erb
<% if @listing.photos.any? %>
  <div class="grid grid-cols-2 gap-2">
    <% @listing.photos.each do |photo| %>
      <%= image_tag photo.variant(:card), class: "rounded-lg object-cover w-full aspect-video" %>
    <% end %>
  </div>
<% end %>
```

---

## Step 8 — Purge on delete (optional UX)

Add a "Remove image" checkbox to the Ad form so users can clear an existing image without re-uploading:

```erb
<% if ad.image.attached? %>
  <label class="flex items-center gap-2 text-sm text-red-600 mt-2">
    <%= form.check_box :remove_image %>
    Remove image
  </label>
<% end %>
```

```ruby
# app/models/ad.rb
attr_accessor :remove_image
before_save -> { image.purge if remove_image == "1" }
```

---

## Step 9 — Production storage (deferred)

Dev uses Disk. Before shipping to production, switch to an object storage service:

- **S3**: uncomment `amazon` block in `config/storage.yml`, set credentials, change `config.active_storage.service = :amazon` in `production.rb`
- **GCS** or **Azure**: same pattern

Consider enabling **direct uploads** (`direct_upload: true` on file fields) to offload large file transfers from the Rails process to the storage service directly.

---

## What's deferred
- Direct uploads (avoids tying up the web process for large files)
- Photo reordering via drag-and-drop
- Image cropping / focal point selection
- Replacing individual listing photos (current form replaces all on save)
- CDN in front of ActiveStorage blob URLs
