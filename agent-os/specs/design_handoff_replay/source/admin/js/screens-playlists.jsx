/* Playlist Builder — visual sequence editor with drag-to-reorder */
function Playlists({ go }) {
  const [items, setItems] = useState([
    { id:"i1", name:"Homes for Sale in Bushwick", type:"Hook", dur:8, tone:"#2f6bff" },
    { id:"i2", name:"124 Maple Ave — Hero", type:"Hero listing", dur:12, tone:"#3a5f8a" },
    { id:"i3", name:"412 Knickerbocker — Hero", type:"Hero listing", dur:12, tone:"#5f6a8a" },
    { id:"i4", name:"Open House — This Saturday", type:"Open house", dur:10, tone:"#0fb5a6" },
    { id:"i5", name:"Browse 6 New Listings", type:"Browse grid", dur:14, tone:"#7c5cff" },
    { id:"i6", name:"Vantage Realty — Brand", type:"Branding", dur:6, tone:"#0b0d12" },
    { id:"i7", name:"Scan for the full tour", type:"CTA", dur:8, tone:"#e8990f" },
  ]);
  const [sel, setSel] = useState("i2");
  const [drag, setDrag] = useState(null);
  const [over, setOver] = useState(null);
  const [library, setLibrary] = useState(false);
  const total = items.reduce((s,i)=>s+i.dur,0);
  const mmss = s => Math.floor(s/60)+":"+String(s%60).padStart(2,"0");
  const setDur = (id,d) => setItems(p=>p.map(i=>i.id===id?{...i,dur:Math.max(3,Math.min(60,i.dur+d))}:i));
  const remove = id => setItems(p=>p.filter(i=>i.id!==id));
  const addItems = (picks) => {
    setItems(p=>[...p, ...picks.map((pk,i)=>({ ...pk, id:"new"+Date.now()+i }))]);
    setLibrary(false);
  };
  const onDrop = (id) => {
    if(!drag||drag===id) return;
    setItems(p=>{ const a=[...p]; const from=a.findIndex(i=>i.id===drag); const to=a.findIndex(i=>i.id===id);
      const [m]=a.splice(from,1); a.splice(to,0,m); return a; });
    setDrag(null); setOver(null);
  };
  const current = items.find(i=>i.id===sel) || items[0];

  return (
    <div className="builder">
      <div className="bld-bar">
        <div style={{ display:"flex", alignItems:"center", gap:12 }}>
          <button className="icon-btn-sm" onClick={()=>go("playlists")} title="Back to playlists"><Icon name="chevronR" size={16} style={{transform:"rotate(180deg)"}}/></button>
          <span style={{ width:34, height:34, borderRadius:9, background:"#2f6bff18", color:"#2f6bff", display:"grid", placeItems:"center" }}><Icon name="playlists" size={17}/></span>
          <div><div style={{ fontSize:14, fontWeight:650 }}>Bushwick · Featured</div><div style={{ fontSize:11.5, color:"var(--slate-400)" }}>Assigned to 2 screens · <span style={{color:"var(--green)"}}>Published v6</span></div></div>
        </div>
        <div style={{ display:"flex", alignItems:"center", gap:14 }}>
          <span className="mono" style={{ fontSize:13, color:"var(--slate-500)" }}><Icon name="clock" size={14} style={{verticalAlign:"-2px",marginRight:5}}/>{mmss(total)} loop</span>
          <button className="btn btn-secondary btn-sm"><Icon name="eye" size={15}/>Preview loop</button>
          <button className="btn btn-primary btn-sm"><Icon name="upload" size={15}/>Publish</button>
        </div>
      </div>

      <div className="bld-body" style={{ gridTemplateColumns:"1fr 380px" }}>
        {/* sequence */}
        <div style={{ padding:"22px 24px", overflowY:"auto" }}>
          <Note>
            <b>Why a Spotify-style list, not a calendar:</b> a playlist is an <b>ordered loop</b>, so sequence and pacing matter more than wall-clock time. Drag to reorder, nudge each slide's duration inline, and watch the proportional timeline below update — the same mental model as a music queue, which everyone already understands.
          </Note>

          {/* proportional timeline */}
          <div style={{ marginBottom:18 }}>
            <div style={{ display:"flex", justifyContent:"space-between", marginBottom:8 }}>
              <span className="bld-sec-t" style={{ margin:0 }}>Loop timeline</span>
              <span className="mono" style={{ fontSize:11.5, color:"var(--slate-400)" }}>{items.length} slides · {mmss(total)}</span>
            </div>
            <div className="timeline-ruler">
              {items.map(i=>(<div key={i.id} className="timeline-seg" style={{ width:(i.dur/total*100)+"%", background:i.tone==="#0b0d12"?"#3b414e":i.tone, opacity:sel===i.id?1:.78 }} onClick={()=>setSel(i.id)}>{i.dur>=8?i.type:""}</div>))}
            </div>
          </div>

          <div className="bld-sec-t">Sequence — drag to reorder</div>
          <div className="pl-track">
            {items.map((i,idx)=>(
              <div key={i.id} className={"pl-item"+(drag===i.id?" drag":"")+(over===i.id?" over":"")+(sel===i.id?"":"")}
                draggable onDragStart={()=>setDrag(i.id)} onDragEnd={()=>{setDrag(null);setOver(null);}}
                onDragOver={e=>{e.preventDefault(); setOver(i.id);}} onDrop={()=>onDrop(i.id)}
                onClick={()=>setSel(i.id)} style={{ background:sel===i.id?"var(--blue-soft)":undefined }}>
                <span className="pl-grip">⋮⋮</span>
                <span className="mono" style={{ width:18, color:"var(--slate-400)", fontSize:12 }}>{idx+1}</span>
                <div className="pl-thumb"><PLThumb item={i}/></div>
                <div style={{ flex:1, minWidth:0 }}>
                  <div className="cell-strong" style={{ fontSize:13.5, overflow:"hidden", textOverflow:"ellipsis", whiteSpace:"nowrap" }}>{i.name}</div>
                  <div style={{ fontSize:11.5, color:"var(--slate-400)" }}>{i.type}</div>
                </div>
                <div className="pl-dur" onClick={e=>e.stopPropagation()}>
                  <button onClick={()=>setDur(i.id,-1)}>−</button>
                  <span className="mono" style={{ width:34, textAlign:"center", fontSize:12.5 }}>0:{String(i.dur).padStart(2,"0")}</span>
                  <button onClick={()=>setDur(i.id,1)}>+</button>
                </div>
                <button className="icon-btn-sm" onClick={e=>{e.stopPropagation();remove(i.id);}}><Icon name="x" size={15}/></button>
              </div>
            ))}
          </div>
          <button className="btn btn-secondary" style={{ width:"100%", marginTop:12 }} onClick={()=>setLibrary(true)}><Icon name="plus" size={15}/>Add content from library</button>
        </div>

        {/* preview panel */}
        <div className="bld-right" style={{ borderLeft:"1px solid var(--line)", display:"flex", flexDirection:"column" }}>
          <div className="bld-sec-t">Now previewing</div>
          <div style={{ aspectRatio:"16/9", borderRadius:11, overflow:"hidden", boxShadow:"var(--sh-md)", position:"relative", marginBottom:14, container:"slide / size" }}>
            <PLPreview item={current}/>
          </div>
          <div style={{ display:"flex", alignItems:"center", gap:10, marginBottom:18 }}>
            <button className="btn btn-icon btn-secondary btn-sm"><Icon name="play" size={15}/></button>
            <div className="bar" style={{ flex:1 }}><span style={{ width:"40%", background:"var(--blue)" }}/></div>
            <span className="mono" style={{ fontSize:12, color:"var(--slate-400)" }}>0:05 / 0:{String(current.dur).padStart(2,"0")}</span>
          </div>
          <div className="bld-sec-t">Slide settings</div>
          <div className="field" style={{ marginBottom:12 }}><label>Type</label>
            <select className="select" defaultValue={current.type}><option>{current.type}</option><option>Hero listing</option><option>Browse grid</option></select></div>
          <div style={{ display:"flex", gap:10 }}>
            <div className="field" style={{ flex:1 }}><label>Duration (s)</label><input className="input mono" value={current.dur} readOnly/></div>
            <div className="field" style={{ flex:1 }}><label>Transition</label><select className="select"><option>Crossfade</option><option>Cut</option><option>Slide</option></select></div>
          </div>
          <div style={{ marginTop:"auto", paddingTop:18, fontSize:12, color:"var(--slate-400)", display:"flex", gap:8, alignItems:"center" }}>
            <Icon name="clock" size={14}/>Changes save to a draft — publish to push live.
          </div>
        </div>
      </div>
      {library && <LibraryModal onClose={()=>setLibrary(false)} onAdd={addItems} existing={items}/>}
    </div>
  );
}

/* Content library picker — multi-select Ads, Listings, and slide templates */
function LibraryModal({ onClose, onAdd, existing }) {
  const [tab, setTab] = useState("ads");
  const [picked, setPicked] = useState([]);
  const [q, setQ] = useState("");

  // build pickable items per tab from central data
  const adItems = ADS.filter(a=>a.status!=="draft").map(a=>({
    key:"ad-"+a.id, name:a.name, type: a.type==="Open House"?"Open house":a.type==="Recruiting"?"Recruiting":a.type==="Branding"?"Branding":"Hero listing",
    dur: a.type==="Branding"?6:a.type==="Open House"?10:12, tone:a.tone, meta:a.campaign, scans:a.scans,
  }));
  const listingItems = LISTINGS.map(l=>({
    key:"li-"+l.id, name:l.addr+" — Hero", type:"Hero listing", dur:12, tone:l.tone, meta:`${l.area} · ${fmtPrice(l.price)}`,
  }));
  const templateItems = [
    { key:"t-hook", name:"Hook — Neighborhood", type:"Hook", dur:8, tone:"#2f6bff", meta:"Attention grabber" },
    { key:"t-browse", name:"Browse Grid — New listings", type:"Browse grid", dur:14, tone:"#7c5cff", meta:"Multi-listing" },
    { key:"t-open", name:"Open House — Weekend", type:"Open house", dur:10, tone:"#0fb5a6", meta:"Event promo" },
    { key:"t-brand", name:"Branding — Awards & stats", type:"Branding", dur:6, tone:"#0b0d12", meta:"Trust builder" },
    { key:"t-recruit", name:"Recruiting — Join our team", type:"Recruiting", dur:10, tone:"#7c5cff", meta:"Hiring" },
    { key:"t-cta", name:"CTA — Scan for tour", type:"CTA", dur:8, tone:"#e8990f", meta:"Closer" },
  ];
  const source = tab==="ads"?adItems : tab==="listings"?listingItems : templateItems;
  const f = q.trim().toLowerCase();
  const list = f ? source.filter(i=>i.name.toLowerCase().includes(f)||(i.meta||"").toLowerCase().includes(f)) : source;
  const toggle = (it) => setPicked(p => p.find(x=>x.key===it.key) ? p.filter(x=>x.key!==it.key) : [...p, it]);
  const isOn = (it) => !!picked.find(x=>x.key===it.key);
  const tabs = [["ads","Ads",ADS.filter(a=>a.status!=="draft").length],["listings","Listings",LISTINGS.length],["templates","Slide templates",templateItems.length]];

  return (
    <div className="modal-bg" onClick={onClose}>
      <div className="modal" onClick={e=>e.stopPropagation()} style={{ maxWidth:680, height:"min(620px,86vh)", display:"flex", flexDirection:"column" }}>
        <div className="modal-head" style={{ position:"relative", paddingBottom:14 }}>
          <button className="icon-btn-sm" style={{ position:"absolute", right:16, top:16 }} onClick={onClose}><Icon name="x" size={16}/></button>
          <h3>Add content from library</h3>
          <p>Pick existing ads, generate a hero from a listing, or drop in a slide template.</p>
          <div style={{ display:"flex", alignItems:"center", gap:12, marginTop:14 }}>
            <div className="seg">
              {tabs.map(([v,l,n])=>(<button key={v} className={"seg-btn"+(tab===v?" on":"")} onClick={()=>setTab(v)}>{l}<span className="lib-tabn">{n}</span></button>))}
            </div>
            <div className="search" style={{ flex:1 }}><Icon name="search" size={15}/><input className="input" placeholder="Search…" value={q} onChange={e=>setQ(e.target.value)}/></div>
          </div>
        </div>

        <div className="lib-grid">
          {list.map(it=>{
            const inPlaylist = existing.some(e=>e.name===it.name);
            return (
              <button key={it.key} className={"lib-card"+(isOn(it)?" on":"")} onClick={()=>toggle(it)}>
                <div className="lib-thumb" style={{ background: it.tone==="#0b0d12"?"#0b0d12":`linear-gradient(135deg,#14171f,${it.tone})` }}>
                  <LibThumbBody it={it}/>
                  <span className={"lib-check"+(isOn(it)?" on":"")}>{isOn(it) && <Icon name="check" size={12} sw={3}/>}</span>
                  {inPlaylist && <span className="lib-inuse">In playlist</span>}
                </div>
                <div className="lib-meta">
                  <div className="lib-name">{it.name}</div>
                  <div className="lib-sub"><span className="badge badge-gray" style={{fontSize:10}}>{it.type}</span><span className="mono" style={{fontSize:11,color:"var(--slate-400)"}}>0:{String(it.dur).padStart(2,"0")}</span></div>
                </div>
              </button>
            );
          })}
          {list.length===0 && <div style={{ gridColumn:"1/-1", textAlign:"center", color:"var(--slate-400)", padding:"40px", fontSize:14 }}>No matches for “{q}”</div>}
        </div>

        <div className="modal-foot" style={{ justifyContent:"space-between" }}>
          <span style={{ fontSize:13, color:"var(--slate-500)", fontWeight:550 }}>{picked.length ? `${picked.length} selected · +0:${String(picked.reduce((s,i)=>s+i.dur,0)).padStart(2,"0")} to loop` : "Select items to add"}</span>
          <div style={{ display:"flex", gap:10 }}>
            <button className="btn btn-secondary" onClick={onClose}>Cancel</button>
            <button className="btn btn-primary" disabled={!picked.length} style={{ opacity:picked.length?1:.5, pointerEvents:picked.length?"auto":"none" }} onClick={()=>onAdd(picked)}><Icon name="plus" size={15}/>Add {picked.length||""} to playlist</button>
          </div>
        </div>
      </div>
    </div>
  );
}
function LibThumbBody({ it }) {
  const big = { fontSize:16, fontWeight:800, letterSpacing:"-.02em", lineHeight:1 };
  if (it.type==="Open house") return <div style={{color:"#fff"}}><div style={{fontSize:8,fontWeight:700,opacity:.8,letterSpacing:".1em"}}>OPEN HOUSE</div><div style={big}>Sat 2–4PM</div></div>;
  if (it.type==="Recruiting") return <div style={{color:"#fff"}}><div style={{fontSize:8,fontWeight:700,opacity:.8,letterSpacing:".1em"}}>HIRING</div><div style={big}>Join us</div></div>;
  if (it.type==="Branding") return <div style={{color:"#fff"}}><div style={big}>Vantage</div><div style={{fontSize:9,opacity:.7}}>#1 in BK</div></div>;
  if (it.type==="Hook") return <div style={{color:"#fff"}}><div style={{...big,fontSize:14}}>Homes in Bushwick</div></div>;
  if (it.type==="Browse grid") return <div style={{color:"#fff"}}><div style={big}>6 Listings</div><div style={{fontSize:9,opacity:.7}}>this week</div></div>;
  if (it.type==="CTA") return <div style={{color:"#fff",display:"flex",alignItems:"center",gap:6}}><span style={{width:18,height:18,background:"#fff",borderRadius:3}}/><div style={{...big,fontSize:13}}>Scan</div></div>;
  return <div style={{color:"#fff",display:"flex",alignItems:"flex-end",justifyContent:"space-between"}}>
    <div><div style={{fontSize:8,fontWeight:700,color:"#7aa2ff",letterSpacing:".08em"}}>FOR SALE</div><div style={big}>{it.meta&&it.meta.includes("$")?it.meta.split("· ")[1]||"$1.25M":"$1.25M"}</div></div>
    <span style={{width:18,height:18,background:"#fff",borderRadius:3}}/>
  </div>;
}
window.Playlists = Playlists;

function PLThumb({ item }) {
  return <div style={{ position:"absolute", inset:0, background: item.tone==="#0b0d12"?"#0b0d12":`linear-gradient(135deg,#14171f,${item.tone}55)`, display:"grid", placeItems:"center" }}>
    <span style={{ width:14, height:14, borderRadius:3, background:item.tone==="#0b0d12"?"linear-gradient(135deg,#2f6bff,#0fb5a6)":"rgba(255,255,255,.7)" }}/>
  </div>;
}
function PLPreview({ item }) {
  const map = {
    "Hook": ["Homes for Sale", "in Bushwick", "#2f6bff"],
    "Hero listing": [item.name.split(" — ")[0], "$1,250,000 · 3bd 2ba", "#3a5f8a"],
    "Open house": ["OPEN HOUSE", "Sat 2–4PM", "#0fb5a6"],
    "Browse grid": ["6 New Listings", "This Week", "#7c5cff"],
    "Branding": ["Vantage Realty", "#1 in Brooklyn", "#0b0d12"],
    "CTA": ["Scan for tours", "→ instant booking", "#e8990f"],
  };
  const [a,b,c] = map[item.type] || ["Slide","",item.tone];
  return <div style={{ position:"absolute", inset:0, background:c==="#0b0d12"?"#0b0d12":`linear-gradient(135deg,#0b0d12,${c}66)`, color:"#fff", display:"flex", flexDirection:"column", justifyContent:"flex-end", padding:"18px" }}>
    <div style={{ fontSize:20, fontWeight:700, letterSpacing:"-.02em", lineHeight:1.05 }}>{a}</div>
    <div style={{ fontSize:12.5, opacity:.8, marginTop:3 }}>{b}</div>
    <div style={{ position:"absolute", right:16, bottom:16, width:30, height:30, background:"#fff", borderRadius:5 }}/>
  </div>;
}
window.Playlists = Playlists;
