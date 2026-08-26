/* Sites management — cards, map, create flow, detail */
function Sites({ go }) {
  const [view, setView] = useState("cards");
  const [creating, setCreating] = useState(false);
  const [active, setActive] = useState(null);
  const [hover, setHover] = useState(SITES[2]);

  return (
    <div className="page">
      <Note>
        <b>Sites = physical locations.</b> A brokerage owner thinks geographically (“how's the Hudson Yards gallery doing?”), so the default is a <b>visual card grid</b> with live screen-health, not a table. The <b>map view</b> reinforces the mental model for multi-location accounts and surfaces offline sites spatially.
      </Note>

      <div className="ph-head">
        <div><h2>Sites</h2><p>5 locations · 16 screens · 13 players online</p></div>
        <div className="ph-actions">
          <Segmented options={[{value:"cards",label:"Cards",icon:"grid"},{value:"map",label:"Map",icon:"map"}]} value={view} onChange={setView} />
          <button className="btn btn-primary" onClick={()=>setCreating(true)}><Icon name="plus" size={15}/>New site</button>
        </div>
      </div>

      {view === "cards" ? (
        <div className="card-grid" style={{ gridTemplateColumns: "repeat(3, 1fr)" }}>
          {SITES.map(s => (
            <div className="site-card" key={s.id} onClick={()=>setActive(s)}>
              <div className="ph" data-label="location photo" style={{ height: 124, background: s.color+"14" }}>
                <div style={{ position:"absolute", inset:0, background:`linear-gradient(135deg, ${s.color}26, transparent)` }} />
                <span style={{ position:"absolute", top:12, left:12 }} className="badge badge-gray">{s.type}</span>
                <span style={{ position:"absolute", top:12, right:12 }} className={"badge " + (s.online===s.screens?"badge-green":"badge-amber")}>
                  <span className="dot"/>{s.online}/{s.screens} live</span>
              </div>
              <div style={{ padding: "14px 16px 16px" }}>
                <h3 style={{ fontSize:16, fontWeight:650, margin:"0 0 3px", letterSpacing:"-.01em" }}>{s.name}</h3>
                <div style={{ fontSize:12.5, color:"var(--slate-400)", display:"flex", alignItems:"center", gap:5 }}>
                  <Icon name="sites" size={13}/>{s.addr}</div>
                <div style={{ display:"flex", gap:18, marginTop:14, paddingTop:14, borderTop:"1px solid var(--line-2)" }}>
                  <MiniStat label="Screens" val={s.screens} />
                  <MiniStat label="Online" val={s.online} color={s.online===s.screens?"var(--green)":"var(--amber)"} />
                  <MiniStat label="Scans" val={s.scans.toLocaleString()} />
                </div>
              </div>
            </div>
          ))}
          {/* add tile */}
          <button className="site-card" onClick={()=>setCreating(true)} style={{ border:"1.5px dashed var(--line)", background:"transparent", display:"grid", placeItems:"center", minHeight:240, cursor:"pointer", color:"var(--slate-400)" }}>
            <div style={{ textAlign:"center" }}>
              <div style={{ width:44, height:44, borderRadius:12, background:"var(--surface)", border:"1px solid var(--line)", display:"grid", placeItems:"center", margin:"0 auto 10px", color:"var(--blue)" }}><Icon name="plus" size={20}/></div>
              <div style={{ fontSize:14, fontWeight:600, color:"var(--ink-800)" }}>Add a site</div>
              <div style={{ fontSize:12.5, marginTop:2 }}>Connect a new location</div>
            </div>
          </button>
        </div>
      ) : (
        <div className="mapwrap">
          <div className="map-grid" />
          {SITES.map(s => (
            <div className="map-pin" key={s.id} style={{ left: s.x+"%", top: s.y+"%" }} onMouseEnter={()=>setHover(s)} onClick={()=>setActive(s)}>
              <div className="pin-dot" style={{ background: s.online===s.screens? s.color : "var(--amber)" }}><b>{s.screens}</b></div>
            </div>
          ))}
          {hover && (
            <div className="map-card">
              <span className="badge badge-gray" style={{ marginBottom:8 }}>{hover.type}</span>
              <h3 style={{ fontSize:15, fontWeight:650, margin:"0 0 3px" }}>{hover.name}</h3>
              <div style={{ fontSize:12, color:"var(--slate-400)", marginBottom:10 }}>{hover.addr}</div>
              <div style={{ display:"flex", gap:16 }}>
                <MiniStat label="Screens" val={hover.screens} />
                <MiniStat label="Online" val={hover.online} color={hover.online===hover.screens?"var(--green)":"var(--amber)"} />
                <MiniStat label="Scans" val={hover.scans.toLocaleString()} />
              </div>
            </div>
          )}
        </div>
      )}

      {creating && <NewSiteModal onClose={()=>setCreating(false)} />}
      {active && <SiteDetail site={active} onClose={()=>setActive(null)} go={go} />}
    </div>
  );
}

function MiniStat({ label, val, color }) {
  return <div><div className="mono cell-strong" style={{ fontSize:16, color: color||"var(--ink-900)" }}>{val}</div><div style={{ fontSize:11, color:"var(--slate-400)" }}>{label}</div></div>;
}

function NewSiteModal({ onClose }) {
  const [step, setStep] = useState(1);
  return (
    <div className="modal-bg" onClick={onClose}>
      <div className="modal" onClick={e=>e.stopPropagation()}>
        <div className="modal-head" style={{ position:"relative" }}>
          <button className="icon-btn-sm" style={{ position:"absolute", right:16, top:16 }} onClick={onClose}><Icon name="x" size={16}/></button>
          <div style={{ display:"flex", gap:8, marginBottom:14 }}>
            {[1,2].map(n=><div key={n} style={{ height:4, flex:1, borderRadius:99, background: step>=n?"var(--blue)":"var(--surface-3)" }}/>)}
          </div>
          <h3>{step===1?"New site":"Almost there"}</h3>
          <p>{step===1?"Tell us about this location.":"Add screens now or invite the on-site team to finish setup."}</p>
        </div>
        <div className="modal-body">
          {step===1 ? <>
            <div className="field"><label>Site name</label><input className="input" placeholder="e.g. Bushwick Flagship" defaultValue="" autoFocus/></div>
            <div className="field"><label>Location type</label>
              <select className="select" defaultValue="Brokerage"><option>Brokerage</option><option>Leasing Office</option><option>Sales Gallery</option><option>Event Location</option></select></div>
            <div className="field"><label>Street address</label><input className="input" placeholder="1247 Myrtle Ave, Brooklyn NY"/></div>
          </> : <>
            <div className="field"><label>How many screens?</label><input className="input" type="number" defaultValue="4"/></div>
            <div style={{ display:"flex", gap:10, background:"var(--blue-soft)", border:"1px solid #d9e4ff", borderRadius:11, padding:"12px 14px" }}>
              <Icon name="players" size={18} style={{ color:"var(--blue-strong)", flex:"none", marginTop:1 }}/>
              <div style={{ fontSize:12.5, lineHeight:1.5, color:"var(--slate-500)" }}>You'll pair each screen with a player device next. RePlay generates a 6-digit code you enter on the Fire Stick or signage device.</div>
            </div>
          </>}
        </div>
        <div className="modal-foot">
          {step===2 && <button className="btn btn-ghost" onClick={()=>setStep(1)}>Back</button>}
          <button className="btn btn-secondary" onClick={onClose}>Cancel</button>
          <button className="btn btn-primary" onClick={()=> step===1 ? setStep(2) : onClose()}>{step===1?"Continue":"Create site"}</button>
        </div>
      </div>
    </div>
  );
}

function SiteDetail({ site, onClose, go }) {
  const screens = SCREENS.filter(s => s.site === site.name);
  return (
    <div className="modal-bg" onClick={onClose} style={{ justifyItems:"end", placeItems:"stretch" }}>
      <div onClick={e=>e.stopPropagation()} style={{ marginLeft:"auto", width:"min(560px,100%)", height:"100%", background:"var(--surface)", boxShadow:"var(--sh-pop)", display:"flex", flexDirection:"column", animation:"slideIn .22s cubic-bezier(.2,.9,.3,1)" }}>
        <div className="ph" data-label="location photo" style={{ height:170, background:site.color+"18", flex:"none" }}>
          <div style={{ position:"absolute", inset:0, background:`linear-gradient(135deg, ${site.color}30, transparent)` }}/>
          <button className="icon-btn-sm" style={{ position:"absolute", right:14, top:14, background:"rgba(255,255,255,.9)" }} onClick={onClose}><Icon name="x" size={16}/></button>
          <span className="badge badge-gray" style={{ position:"absolute", left:16, top:16 }}>{site.type}</span>
        </div>
        <div style={{ padding:"20px 24px", flex:1, overflowY:"auto" }}>
          <h2 style={{ fontSize:22, fontWeight:700, letterSpacing:"-.02em", margin:"0 0 4px" }}>{site.name}</h2>
          <div style={{ fontSize:13.5, color:"var(--slate-400)", display:"flex", alignItems:"center", gap:6, marginBottom:18 }}><Icon name="sites" size={14}/>{site.addr}</div>
          <div className="page-grid" style={{ gridTemplateColumns:"repeat(3,1fr)", marginBottom:22 }}>
            <StatCard label="Screens" value={site.screens} icon="screens" accent="#2f6bff"/>
            <StatCard label="Online" value={site.online+"/"+site.screens} icon="players" accent="#1f9d57"/>
            <StatCard label="Scans (mo)" value={site.scans.toLocaleString()} icon="qr" accent="#e8990f"/>
          </div>
          <h3 style={{ fontSize:14, fontWeight:650, margin:"0 0 12px" }}>Screens at this site</h3>
          <div className="page-grid" style={{ gap:10 }}>
            {screens.map(sc=>(
              <div key={sc.id} style={{ display:"flex", alignItems:"center", gap:12, border:"1px solid var(--line)", borderRadius:11, padding:"11px 13px" }}>
                <div className="ph" data-label="" style={{ width:54, height:34, borderRadius:6, flex:"none", background:"var(--ink-900)" }}/>
                <div style={{ flex:1 }}><div className="cell-strong" style={{ fontSize:13.5 }}>{sc.name}</div><div style={{ fontSize:12, color:"var(--slate-400)" }}>{sc.playlist}</div></div>
                <Badge status={sc.status}/>
              </div>
            ))}
          </div>
        </div>
        <div style={{ padding:"14px 24px", borderTop:"1px solid var(--line)", display:"flex", gap:10 }}>
          <button className="btn btn-secondary" style={{ flex:1 }} onClick={()=>go("screens")}>Manage screens</button>
          <button className="btn btn-primary" style={{ flex:1 }} onClick={()=>go("playlists")}>Edit playlist</button>
        </div>
      </div>
    </div>
  );
}
window.Sites = Sites;
