# Feature Spec — "Add content from library" (Playlist Builder)

A multi-select content picker modal that appends slides to a playlist. Lives in the Playlist Builder (`admin/js/screens-playlists.jsx`).

## Purpose
The "Add content from library" button in the Playlist Builder's left sequence panel was a dead button. This modal lets a user pull existing **Ads**, generate hero slides from **Listings**, or drop in **slide templates**, multi-select them, and append them to the current playlist loop. It's the Ad→Playlist wiring.

## Data sources (from `admin/js/data.jsx`)
- `ADS` — array of ads `{ id, name, campaign, type, status, scans, ctr, updated, tone, layout }`. Use only `status !== "draft"`.
- `LISTINGS` — `{ id, addr, area, price, beds, baths, sqft, status, type, tone }`.
- `fmtPrice(n)` helper for price formatting.

## Slide item shape (what gets added to the playlist)
Playlist items are `{ id, name, type, dur, tone }` where:
- `type` ∈ `"Hook" | "Hero listing" | "Open house" | "Browse grid" | "Branding" | "Recruiting" | "CTA"`
- `dur` = seconds (int)
- `tone` = hex used for the slide's gradient thumbnail
- `id` must be unique — generate on add (e.g. `"new" + Date.now() + i`).

## Component: `LibraryModal({ onClose, onAdd, existing })`
- `onAdd(picks)` — receives array of selected item objects; parent appends them (mapping fresh ids) and closes.
- `existing` — current playlist items, used to show an "In playlist" badge when `name` matches.

### State
- `tab`: `"ads" | "listings" | "templates"` (default `"ads"`)
- `picked`: array of selected item objects (keyed by a `key` field)
- `q`: search string

### Tab item builders
- **Ads tab:** map `ADS` (non-draft) → `{ key:"ad-"+id, name, type (map Open House/Recruiting/Branding else "Hero listing"), dur (Branding 6 / Open House 10 / else 12), tone, meta: campaign, scans }`.
- **Listings tab:** map `LISTINGS` → `{ key:"li-"+id, name: addr+" — Hero", type:"Hero listing", dur:12, tone, meta:`${area} · ${fmtPrice(price)}` }`.
- **Templates tab:** hardcoded 6: Hook (8s), Browse grid (14s), Open house (10s), Branding (6s), Recruiting (10s), CTA (8s) — each with a tone + short `meta`.

### Filtering
Case-insensitive match of `q` against `name` and `meta`.

### Layout
- Reuse existing modal classes: `.modal-bg`, `.modal` (set maxWidth 680, height `min(620px,86vh)`, flex column).
- Header: title "Add content from library", subtitle, then a row with a `.seg` segmented control (3 tabs, each showing a count pill `.lib-tabn`) + a `.search` input.
- Body: `.lib-grid` — `repeat(3,1fr)` grid of `.lib-card` (scrollable, `flex:1`).
- Each card: `.lib-thumb` (16:9 gradient `linear-gradient(135deg,#14171f,${tone})`, renders a mini headline via a `LibThumbBody` switch on `type`), a circular `.lib-check` (filled when selected), optional `.lib-inuse` badge; then `.lib-meta` with `.lib-name` + a `.lib-sub` row (type badge + `0:SS` duration).
- Footer `.modal-foot` (space-between): left = live summary `"{n} selected · +0:{sumDur} to loop"` or "Select items to add"; right = Cancel + primary "Add {n} to playlist" (disabled when none picked).

### Selection
- Click card toggles membership in `picked` (match by `key`).
- `.lib-card.on` + `.lib-check.on` reflect selected.

## Wiring into `Playlists({ go })`
1. Add state `const [library, setLibrary] = useState(false)`.
2. Add handler:
   ```js
   const addItems = (picks) => {
     setItems(p => [...p, ...picks.map((pk,i) => ({ ...pk, id:"new"+Date.now()+i }))]);
     setLibrary(false);
   };
   ```
3. The library button: `onClick={() => setLibrary(true)}`.
4. Mount before the component's closing tag: `{library && <LibraryModal onClose={()=>setLibrary(false)} onAdd={addItems} existing={items} />}`.
5. The loop-duration label (`total = items.reduce((s,i)=>s+i.dur,0)`) updates automatically.

## CSS to add (in `admin/admin.css`)
```css
.lib-tabn { font-size:10.5px; font-weight:700; background:var(--surface); border:1px solid var(--line); color:var(--slate-400); border-radius:99px; padding:0 5px; margin-left:5px; min-width:16px; display:inline-grid; place-items:center; }
.seg-btn.on .lib-tabn { background:var(--blue-soft); border-color:transparent; color:var(--blue-strong); }
.lib-grid { flex:1; overflow-y:auto; padding:16px 22px; display:grid; grid-template-columns:repeat(3,1fr); gap:12px; align-content:start; }
.lib-card { text-align:left; padding:0; border:1px solid var(--line); border-radius:var(--r-md); background:var(--surface); cursor:pointer; overflow:hidden; transition:border-color .14s, box-shadow .14s, transform .12s; }
.lib-card:hover { border-color:var(--slate-300); transform:translateY(-2px); box-shadow:var(--sh-sm); }
.lib-card.on { border-color:var(--blue); box-shadow:0 0 0 3px rgba(47,107,255,.14); }
.lib-thumb { aspect-ratio:16/9; position:relative; display:flex; flex-direction:column; justify-content:flex-end; padding:10px; }
.lib-check { position:absolute; top:8px; right:8px; width:20px; height:20px; border-radius:50%; border:2px solid rgba(255,255,255,.7); background:rgba(11,13,18,.25); display:grid; place-items:center; color:#fff; }
.lib-check.on { background:var(--blue); border-color:#fff; }
.lib-inuse { position:absolute; top:8px; left:8px; font-size:9.5px; font-weight:700; letter-spacing:.04em; text-transform:uppercase; color:#fff; background:rgba(11,13,18,.5); backdrop-filter:blur(4px); padding:2px 6px; border-radius:99px; }
.lib-meta { padding:9px 11px 11px; }
.lib-name { font-size:12.5px; font-weight:600; line-height:1.3; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
.lib-sub { display:flex; align-items:center; justify-content:space-between; margin-top:6px; }
```

## Acceptance
- Button opens modal; 3 tabs show correct counts; search filters; clicking cards toggles selection with a checkmark.
- Footer total updates ("N selected · +0:SS to loop"); primary button disabled at 0, labeled "Add N to playlist".
- Confirm appends N slides to the sequence, updates the loop time, and closes the modal.
- Items already in the playlist show an "In playlist" badge.

## Gotchas
- This is the no-build React+Babel setup — no imports; `LibraryModal` and `LibThumbBody` live in the same file as `Playlists`. End the file with `window.Playlists = Playlists;` (keep `PLThumb`/`PLPreview` declarations intact — don't orphan them).
- Modal is `position:fixed`; it won't appear in html-to-image screenshots. Verify via live DOM.
