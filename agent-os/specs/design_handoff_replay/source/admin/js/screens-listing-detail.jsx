/* Listing Detail — full property page (admin) */

const FEAT_BY_TYPE = {
  Townhouse: ["Private garden", "Finished basement", "Original detail", "Central air", "Washer / dryer", "Off-street parking"],
  Condo: ["Doorman", "Fitness center", "Common roof deck", "Floor-to-ceiling glass", "In-unit laundry", "Storage unit"],
  "Co-op": ["Pre-war detail", "Hardwood floors", "Live-in super", "Elevator building", "Bike storage", "Pet friendly"],
  Apartment: ["In-unit laundry", "Stainless appliances", "Hardwood floors", "Pet friendly", "High ceilings", "Dishwasher"],
};

function listingDesc(l) {
  const rent = l.price < 100000;
  const kind = l.type.toLowerCase();
  const lead = rent
    ? `A turnkey ${l.beds}-bedroom ${kind} in ${l.area}, offering ${l.sqft.toLocaleString()} sq ft of light-filled, move-in-ready space.`
    : `A ${l.beds}-bedroom, ${l.baths}-bath ${kind} spanning ${l.sqft.toLocaleString()} sq ft in the heart of ${l.area}.`;
  return `${lead} Generous proportions, abundant natural light, and walkable access to transit, parks, and the neighborhood's best dining make this a standout on the block.`;
}

function ListingDetail({ id, go, openEditor }) {
  const l = LISTINGS.find(x => x.id === id);
  if (!l) return <div className="page"><p>Listing not found.</p></div>;

  const rent = l.price < 100000;
  const num = (l.addr.match(/^\d+/) || [""])[0];
  const ads = ADS.filter(a => a.type === "Listing" && num && a.name.includes(num));
  const feats = FEAT_BY_TYPE[l.type] || FEAT_BY_TYPE.Apartment;
  const ppsf = Math.round(l.price / l.sqft);
  const spark = Array.from({ length: 12 }, (_, i) => Math.round(l.lscans / 12 * (0.55 + 0.45 * Math.sin(i * 0.9) + i * 0.04)));
  const ctr = (8 + (l.lscans % 9)).toFixed(1);

  const Row = ({ k, v }) => (
    <div className="ld-detail-row"><span className="k">{k}</span><span className="v">{v}</span></div>
  );

  return (
    <div className="page">
      <button className="ld-back" onClick={() => go("listings")}>
        <Icon name="chevronR" size={15} style={{ transform: "rotate(180deg)" }} />Listings
      </button>

      <div className="ph-head" style={{ alignItems: "flex-start" }}>
        <div>
          <div style={{ display: "flex", alignItems: "center", gap: 12, marginBottom: 4 }}>
            <h2 style={{ margin: 0 }}>{l.addr}</h2>
            <Badge status={l.status} />
          </div>
          <p style={{ display: "flex", alignItems: "center", gap: 7 }}>
            <Icon name="sites" size={14} />{l.area} · {l.type} · <span className="mono">{l.mls}</span>
          </p>
        </div>
        <div className="ph-actions">
          <button className="btn btn-secondary" onClick={() => openEditor && openEditor(l.id)}><Icon name="upload" size={15} />Edit listing</button>
          <button className="btn btn-primary" onClick={() => go("ad-builder")}><Icon name="ads" size={15} />Use in ad</button>
          <button className="btn btn-icon btn-secondary"><Icon name="dots" size={17} /></button>
        </div>
      </div>

      {/* gallery */}
      <div className="ld-gallery">
        <div className="ph ld-hero" data-label="hero photo" style={{ background: l.tone + "26" }}>
          <div style={{ position: "absolute", inset: 0, background: `linear-gradient(150deg, ${l.tone}40, transparent 65%)` }} />
          <span className="ld-count"><Icon name="grid" size={13} />12 photos</span>
        </div>
        <div className="ph" data-label="kitchen" style={{ background: l.tone + "1c" }} />
        <div className="ph" data-label="living" style={{ background: l.tone + "1c" }} />
        <div className="ph" data-label="bedroom" style={{ background: l.tone + "1c" }} />
        <div className="ph" data-label="exterior" style={{ background: l.tone + "1c" }}>
          <button className="ld-more">+8 more</button>
        </div>
      </div>

      {/* spec strip */}
      <div className="card ld-specs">
        <div className="ld-spec ld-spec-price">
          <div className="ld-spec-v tabular">{fmtPrice(l.price)}</div>
          <div className="ld-spec-k">{rent ? "Asking rent" : "List price"}</div>
        </div>
        <div className="ld-spec"><div className="ld-spec-v tabular"><Icon name="bed" size={17} />{l.beds}</div><div className="ld-spec-k">Bedrooms</div></div>
        <div className="ld-spec"><div className="ld-spec-v tabular"><Icon name="bath" size={17} />{l.baths}</div><div className="ld-spec-k">Bathrooms</div></div>
        <div className="ld-spec"><div className="ld-spec-v tabular"><Icon name="sqft" size={17} />{l.sqft.toLocaleString()}</div><div className="ld-spec-k">Interior sq ft</div></div>
        <div className="ld-spec"><div className="ld-spec-v tabular">{rent ? "12 mo" : "$" + ppsf.toLocaleString()}</div><div className="ld-spec-k">{rent ? "Lease term" : "Price / sq ft"}</div></div>
      </div>

      {/* body */}
      <div className="ld-grid">
        <div style={{ display: "flex", flexDirection: "column", gap: 18 }}>
          <div className="card card-pad">
            <h3 className="ld-h3">About this property</h3>
            <p style={{ margin: 0, fontSize: 14, lineHeight: 1.65, color: "var(--ink-700)", textWrap: "pretty" }}>{l.desc && l.desc.trim() ? l.desc : listingDesc(l)}</p>
          </div>

          <div className="card card-pad">
            <h3 className="ld-h3">Features &amp; amenities</h3>
            <div className="ld-feat">
              {feats.map(f => (<span key={f}><Icon name="check" size={13} sw={2.2} />{f}</span>))}
            </div>
          </div>

          <div className="card card-pad">
            <h3 className="ld-h3">Property details</h3>
            <Row k="Property type" v={l.type} />
            <Row k="Status" v={l.status} />
            <Row k="Bedrooms" v={l.beds} />
            <Row k="Bathrooms" v={l.baths} />
            <Row k="Interior" v={l.sqft.toLocaleString() + " sq ft"} />
            <Row k="Year built" v={l.year} />
            <Row k={rent ? "Lease term" : "Price per sq ft"} v={rent ? "12 months" : "$" + ppsf.toLocaleString()} />
            <Row k="Neighborhood" v={l.area} />
            <Row k="MLS #" v={<span className="mono">{l.mls}</span>} />
            <Row k="Days on market" v={l.dom + " days"} />
          </div>

          {/* on-screen presence */}
          <div className="card card-pad">
            <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 14 }}>
              <h3 className="ld-h3" style={{ margin: 0 }}>Ads built from this listing</h3>
              <button className="btn btn-ghost btn-sm" onClick={() => go("ads")}>View all<Icon name="chevronR" size={14} /></button>
            </div>
            {ads.length ? (
              <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
                {ads.map(a => (
                  <div key={a.id} className="ld-ad" onClick={() => go("ad-builder")}>
                    <div className="ph" data-label="" style={{ width: 64, height: 40, borderRadius: 7, flex: "none", background: a.tone }} />
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div className="cell-strong" style={{ fontSize: 13.5 }}>{a.name}</div>
                      <div style={{ fontSize: 12, color: "var(--slate-400)" }}>{a.layout} layout · {a.campaign}</div>
                    </div>
                    <div style={{ textAlign: "right", marginRight: 8 }}>
                      <div className="mono cell-strong" style={{ fontSize: 13.5 }}>{a.scans.toLocaleString()}</div>
                      <div style={{ fontSize: 11, color: "var(--slate-400)" }}>scans</div>
                    </div>
                    <Badge status={a.status} />
                  </div>
                ))}
              </div>
            ) : (
              <div className="ld-empty">
                <span className="ld-empty-ic"><Icon name="ads" size={20} /></span>
                <div style={{ flex: 1 }}>
                  <div className="cell-strong" style={{ fontSize: 13.5 }}>No ads yet</div>
                  <div style={{ fontSize: 12.5, color: "var(--slate-400)" }}>Turn this listing into signage in one step.</div>
                </div>
                <button className="btn btn-primary btn-sm" onClick={() => go("ad-builder")}><Icon name="plus" size={14} />Create ad</button>
              </div>
            )}
          </div>
        </div>

        {/* sidebar */}
        <div style={{ display: "flex", flexDirection: "column", gap: 18 }}>
          <div className="card card-pad">
            <h3 className="ld-h3">Signage performance</h3>
            <div style={{ display: "flex", alignItems: "baseline", gap: 8 }}>
              <div className="tabular" style={{ fontSize: 30, fontWeight: 700, letterSpacing: "-0.02em" }}>{l.lscans.toLocaleString()}</div>
              <div style={{ fontSize: 12.5, color: "var(--slate-400)" }}>QR scans · 30d</div>
            </div>
            <Sparkline data={spark} color="var(--blue)" h={38} />
            <div style={{ display: "flex", gap: 18, marginTop: 14, paddingTop: 14, borderTop: "1px solid var(--line-2)" }}>
              <div><div className="mono cell-strong" style={{ fontSize: 16 }}>{ctr}%</div><div style={{ fontSize: 11, color: "var(--slate-400)" }}>Scan-through</div></div>
              <div><div className="mono cell-strong" style={{ fontSize: 16 }}>{ads.length}</div><div style={{ fontSize: 11, color: "var(--slate-400)" }}>Active ads</div></div>
              <div><div className="mono cell-strong" style={{ fontSize: 16 }}>{Math.max(1, ads.length)}</div><div style={{ fontSize: 11, color: "var(--slate-400)" }}>On screens</div></div>
            </div>
          </div>

          <div className="card card-pad">
            <h3 className="ld-h3">Listing agent</h3>
            <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
              <Avatar name={l.agent} />
              <div>
                <div className="cell-strong" style={{ fontSize: 14 }}>{l.agent}</div>
                <div style={{ fontSize: 12.5, color: "var(--slate-400)" }}>Vantage Realty</div>
              </div>
            </div>
            <div style={{ display: "flex", gap: 10, marginTop: 14 }}>
              <button className="btn btn-secondary btn-sm" style={{ flex: 1 }}><Icon name="bell" size={14} />Message</button>
              <button className="btn btn-secondary btn-sm" style={{ flex: 1 }}><Icon name="link" size={14} />Profile</button>
            </div>
          </div>

          <Note>
            <b>Synced from MLS.</b> Property facts update automatically on the next sync — edits here only affect how the listing appears in RePlay signage.
          </Note>
        </div>
      </div>
    </div>
  );
}
/* ---------- New / Edit listing ---------- */
const AREAS = ["Bushwick", "Williamsburg", "Manhattan", "Park Slope", "Astoria", "Greenpoint"];
const TONES = ["#3a5f8a", "#6a7c8a", "#8a6f5f", "#5f7a6a", "#7a5f6f", "#5f6a8a", "#4a6a7a", "#7a6a5f"];

function ListingEditor({ id, onClose, onSaved, go }) {
  const existing = id ? LISTINGS.find(x => x.id === id) : null;
  const blank = { addr: "", area: "Bushwick", type: "Apartment", status: "Active", price: "", beds: 1, baths: 1, sqft: "", year: 2020, mls: "", desc: "" };
  const [f, setF] = useState(() => existing ? { ...blank, ...existing, price: String(existing.price) } : blank);
  const set = (k, v) => setF(p => ({ ...p, [k]: v }));
  const featPool = FEAT_BY_TYPE[f.type] || FEAT_BY_TYPE.Apartment;
  const [feats, setFeats] = useState(() => featPool.slice(0, 4));
  const toggleFeat = (x) => setFeats(p => p.includes(x) ? p.filter(y => y !== x) : [...p, x]);

  const valid = f.addr.trim() && f.price && f.sqft;

  const save = () => {
    const vals = { addr: f.addr.trim(), area: f.area, type: f.type, status: f.status,
      price: Number(f.price), beds: Number(f.beds), baths: Number(f.baths), sqft: Number(f.sqft),
      year: Number(f.year), mls: f.mls.trim() || ("RP-" + Math.random().toString(36).slice(2, 7).toUpperCase()), desc: f.desc };
    if (existing) {
      Object.assign(existing, vals);
      onSaved && onSaved();
      onClose();
    } else {
      const nid = "l" + Date.now().toString(36);
      LISTINGS.push({ id: nid, tone: TONES[LISTINGS.length % TONES.length], dom: 0, agent: "Maya Chen", lscans: 0, ...vals });
      onSaved && onSaved();
      onClose();
      go("listing-" + nid);
    }
  };

  return (
    <div className="modal-bg" onClick={onClose}>
      <div className="modal modal-lg" onClick={e => e.stopPropagation()}>
        <div className="modal-head" style={{ position: "relative" }}>
          <button className="icon-btn-sm" style={{ position: "absolute", right: 16, top: 16 }} onClick={onClose}><Icon name="x" size={16} /></button>
          <h3>{existing ? "Edit listing" : "New listing"}</h3>
          <p>{existing ? "Update the property record used across RePlay signage." : "Add a property manually, or sync your MLS to import in bulk."}</p>
        </div>
        <div className="modal-body le-body">
          {!existing && (
            <div className="le-mls">
              <Icon name="refresh" size={16} style={{ color: "var(--blue-strong)", flex: "none" }} />
              <div style={{ flex: 1, fontSize: 12.5, color: "var(--slate-500)", lineHeight: 1.45 }}>Connected to MLS — most listings import automatically. Use this form for off-market or pre-launch properties.</div>
              <button className="btn btn-secondary btn-sm">Sync MLS</button>
            </div>
          )}

          <div className="le-sec">Property</div>
          <div className="field"><label>Street address</label><input className="input" placeholder="124 Maple Ave" value={f.addr} onChange={e => set("addr", e.target.value)} autoFocus /></div>
          <div className="le-grid-3">
            <div className="field"><label>Neighborhood</label><select className="select" value={f.area} onChange={e => set("area", e.target.value)}>{AREAS.map(a => <option key={a}>{a}</option>)}</select></div>
            <div className="field"><label>Type</label><select className="select" value={f.type} onChange={e => set("type", e.target.value)}>{["Apartment", "Condo", "Co-op", "Townhouse"].map(t => <option key={t}>{t}</option>)}</select></div>
            <div className="field"><label>Status</label><select className="select" value={f.status} onChange={e => set("status", e.target.value)}>{["Active", "For Rent", "Pending"].map(s => <option key={s}>{s}</option>)}</select></div>
          </div>

          <div className="le-sec">Pricing &amp; size</div>
          <div className="le-grid-3">
            <div className="field"><label>{f.status === "For Rent" ? "Monthly rent ($)" : "List price ($)"}</label><input className="input mono" type="number" placeholder="1250000" value={f.price} onChange={e => set("price", e.target.value)} /></div>
            <div className="field"><label>Interior (sq ft)</label><input className="input mono" type="number" placeholder="1840" value={f.sqft} onChange={e => set("sqft", e.target.value)} /></div>
            <div className="field"><label>Year built</label><input className="input mono" type="number" value={f.year} onChange={e => set("year", e.target.value)} /></div>
          </div>
          <div className="le-grid-3">
            <div className="field"><label>Bedrooms</label><input className="input mono" type="number" step="1" value={f.beds} onChange={e => set("beds", e.target.value)} /></div>
            <div className="field"><label>Bathrooms</label><input className="input mono" type="number" step="0.5" value={f.baths} onChange={e => set("baths", e.target.value)} /></div>
            <div className="field"><label>MLS #</label><input className="input mono" placeholder="auto" value={f.mls} onChange={e => set("mls", e.target.value)} /></div>
          </div>

          <div className="le-sec">Description</div>
          <div className="field"><textarea className="textarea" rows="3" placeholder="A few sentences buyers will see on the QR landing page…" value={f.desc} onChange={e => set("desc", e.target.value)} /></div>

          <div className="le-sec">Features &amp; amenities</div>
          <div className="ld-feat">
            {featPool.map(x => (
              <button key={x} type="button" className={"le-chip" + (feats.includes(x) ? " on" : "")} onClick={() => toggleFeat(x)}>
                <Icon name={feats.includes(x) ? "check" : "plus"} size={13} sw={2.2} />{x}
              </button>
            ))}
          </div>

          <div className="le-sec">Photos</div>
          <div className="le-drop">
            <Icon name="upload" size={20} style={{ color: "var(--slate-400)" }} />
            <div style={{ fontSize: 13, fontWeight: 550 }}>Drag photos here or <span style={{ color: "var(--blue-strong)" }}>browse</span></div>
            <div style={{ fontSize: 12, color: "var(--slate-400)" }}>JPG or PNG · first image becomes the signage hero</div>
          </div>
        </div>
        <div className="modal-foot">
          <button className="btn btn-secondary" onClick={onClose}>Cancel</button>
          <button className={"btn btn-primary" + (valid ? "" : " is-disabled")} disabled={!valid} onClick={save}>{existing ? "Save changes" : "Create listing"}</button>
        </div>
      </div>
    </div>
  );
}

Object.assign(window, { ListingDetail, ListingEditor });
