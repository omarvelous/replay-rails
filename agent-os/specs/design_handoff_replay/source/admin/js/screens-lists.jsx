/* Ads list + Playlists list (index views) */
function AdsList({ go }) {
  const [view, setView] = useState("grid");
  const [filter, setFilter] = useState("all");
  const list = ADS.filter(a => filter==="all" ? true : a.status===filter);

  return (
    <div className="page">
      <Note>
        <b>Ads index first, builder second.</b> Marketing managers manage a library of ads — duplicating winners, checking scan-through, spotting drafts — far more often than they build from scratch. So Ads opens to a scannable list; the Canva-style builder is one click in via any card or <b>New ad</b>.
      </Note>
      <div className="ph-head">
        <div><h2>Ads</h2><p>{ADS.length} ads · {ADS.filter(a=>a.status==="live").length} live · {ADS.filter(a=>a.status==="draft").length} drafts</p></div>
        <div className="ph-actions">
          <Segmented options={[{value:"grid",label:"Grid",icon:"grid"},{value:"table",label:"Table",icon:"list"}]} value={view} onChange={setView}/>
          <button className="btn btn-primary" onClick={()=>go("ad-builder")}><Icon name="plus" size={15}/>New ad</button>
        </div>
      </div>
      <div className="toolbar">
        <div className="search"><Icon name="search" size={15}/><input className="input" placeholder="Search ads…"/></div>
        <div style={{ display:"flex", gap:8 }}>
          {[["all","All"],["live","Live"],["scheduled","Scheduled"],["draft","Drafts"]].map(([v,l])=>(
            <button key={v} className={"chip"+(filter===v?" on":"")} onClick={()=>setFilter(v)}>{l}</button>
          ))}
        </div>
        <button className="chip"><Icon name="filter" size={14}/>Campaign</button>
      </div>

      {view==="grid" ? (
        <div className="card-grid" style={{ gridTemplateColumns:"repeat(3,1fr)" }}>
          {list.map(a=>(
            <div className="listing-card" key={a.id} onClick={()=>go("ad-builder")}>
              <div className="lc-media" style={{ aspectRatio:"16/9", background:`linear-gradient(135deg, #14171f, ${a.tone})`, position:"relative", display:"flex", flexDirection:"column", justifyContent:"flex-end", padding:14 }}>
                <span className="lc-status"><Badge status={a.status}/></span>
                <AdThumbBody ad={a}/>
              </div>
              <div className="lc-body">
                <div style={{ display:"flex", alignItems:"center", justifyContent:"space-between", gap:8 }}>
                  <span className="cell-strong" style={{ fontSize:14, overflow:"hidden", textOverflow:"ellipsis", whiteSpace:"nowrap" }}>{a.name}</span>
                  <span className="badge badge-gray" style={{ fontSize:10.5, flex:"none" }}>{a.type}</span>
                </div>
                <div style={{ fontSize:12.5, color:"var(--slate-400)", marginTop:3 }}>{a.campaign}</div>
                <div className="lc-specs" style={{ justifyContent:"space-between" }}>
                  <span><Icon name="qr" size={13}/>{a.scans.toLocaleString()} scans</span>
                  <span><Icon name="analytics" size={13}/>{a.ctr}%</span>
                  <span style={{ color:"var(--slate-400)" }}>{a.updated}</span>
                </div>
              </div>
            </div>
          ))}
          <button className="site-card" onClick={()=>go("ad-builder")} style={{ border:"1.5px dashed var(--line)", background:"transparent", display:"grid", placeItems:"center", minHeight:210, cursor:"pointer", color:"var(--slate-400)" }}>
            <div style={{ textAlign:"center" }}>
              <div style={{ width:42, height:42, borderRadius:12, background:"var(--surface)", border:"1px solid var(--line)", display:"grid", placeItems:"center", margin:"0 auto 10px", color:"var(--blue)" }}><Icon name="plus" size={19}/></div>
              <div style={{ fontSize:13.5, fontWeight:600, color:"var(--ink-800)" }}>New ad</div>
              <div style={{ fontSize:12, marginTop:2 }}>Start from a template</div>
            </div>
          </button>
        </div>
      ) : (
        <div className="tbl-wrap">
          <table className="tbl">
            <thead><tr><th style={{paddingLeft:18}}>Ad</th><th>Campaign</th><th>Type</th><th>Status</th><th>Scans</th><th>Scan-through</th><th>Updated</th><th></th></tr></thead>
            <tbody>{list.map(a=>(
              <tr key={a.id} onClick={()=>go("ad-builder")} style={{ cursor:"pointer" }}>
                <td style={{paddingLeft:18}}><div style={{display:"flex",alignItems:"center",gap:11}}>
                  <div style={{ width:54, height:32, borderRadius:6, flex:"none", background:`linear-gradient(135deg,#14171f,${a.tone})` }}/>
                  <span className="cell-strong">{a.name}</span></div></td>
                <td className="muted">{a.campaign}</td>
                <td><span className="badge badge-gray">{a.type}</span></td>
                <td><Badge status={a.status}/></td>
                <td className="mono cell-strong">{a.scans.toLocaleString()}</td>
                <td className="mono muted">{a.ctr}%</td>
                <td className="muted" style={{fontSize:12.5}}>{a.updated}</td>
                <td onClick={e=>e.stopPropagation()}><button className="icon-btn-sm" title="Duplicate"><Icon name="layers" size={15}/></button></td>
              </tr>
            ))}</tbody>
          </table>
        </div>
      )}
    </div>
  );
}
function AdThumbBody({ ad }) {
  if (ad.type==="Open House") return <div style={{color:"#fff"}}><div style={{fontSize:10,fontWeight:700,opacity:.8,letterSpacing:".1em"}}>OPEN HOUSE</div><div style={{fontSize:19,fontWeight:800,letterSpacing:"-.02em"}}>Sat 2–4PM</div></div>;
  if (ad.type==="Recruiting") return <div style={{color:"#fff"}}><div style={{fontSize:10,fontWeight:700,opacity:.8,letterSpacing:".1em"}}>WE'RE HIRING</div><div style={{fontSize:17,fontWeight:800,letterSpacing:"-.02em"}}>Join our team</div></div>;
  if (ad.type==="Branding") return <div style={{color:"#fff"}}><div style={{fontSize:17,fontWeight:800,letterSpacing:"-.02em"}}>Vantage Realty</div><div style={{fontSize:11,opacity:.7}}>#1 in Brooklyn</div></div>;
  return <div style={{color:"#fff",display:"flex",alignItems:"flex-end",justifyContent:"space-between"}}>
    <div><div style={{fontSize:9,fontWeight:700,color:"#7aa2ff",letterSpacing:".08em"}}>FOR SALE</div><div style={{fontSize:20,fontWeight:800,letterSpacing:"-.02em"}}>{ad.name.includes("HY")?"$8.95M":ad.name.includes("Maple")?"$1.25M":ad.name.includes("Bedford")?"$4,200/mo":"$985K"}</div></div>
    <div style={{width:26,height:26,background:"#fff",borderRadius:4}}/>
  </div>;
}

function PlaylistsList({ go }) {
  const [filter, setFilter] = useState("all");
  const list = PLAYLISTS.filter(p => filter==="all" ? true : p.status===filter);
  return (
    <div className="page">
      <Note>
        <b>Playlists index first, editor second.</b> An office manager's daily question is “what's scheduled where, and is it live?” — answered here by site, screen-count, and publish status. The visual loop strip previews pacing at a glance; click any row to open the drag-and-drop editor.
      </Note>
      <div className="ph-head">
        <div><h2>Playlists</h2><p>{PLAYLISTS.length} playlists · {PLAYLISTS.filter(p=>p.status==="published").length} published · {PLAYLISTS.filter(p=>p.status==="draft").length} drafts</p></div>
        <div className="ph-actions">
          <button className="btn btn-primary" onClick={()=>go("playlist-builder")}><Icon name="plus" size={15}/>New playlist</button>
        </div>
      </div>
      <div className="toolbar">
        <div className="search"><Icon name="search" size={15}/><input className="input" placeholder="Search playlists…"/></div>
        <div style={{ display:"flex", gap:8 }}>
          {[["all","All"],["published","Published"],["draft","Drafts"]].map(([v,l])=>(
            <button key={v} className={"chip"+(filter===v?" on":"")} onClick={()=>setFilter(v)}>{l}</button>
          ))}
        </div>
      </div>

      <div className="page-grid" style={{ gap:12 }}>
        {list.map(p=>(
          <div key={p.id} className="pl-row" onClick={()=>go("playlist-builder")}>
            <span style={{ width:38, height:38, borderRadius:9, background:"#2f6bff14", color:"#2f6bff", display:"grid", placeItems:"center", flex:"none" }}><Icon name="playlists" size={18}/></span>
            <div style={{ width:210, flex:"none" }}>
              <div style={{ display:"flex", alignItems:"center", gap:8 }}><span className="cell-strong" style={{ fontSize:14.5 }}>{p.name}</span></div>
              <div style={{ fontSize:12, color:"var(--slate-400)", marginTop:2 }}>{p.site}</div>
            </div>
            <div style={{ flex:1, minWidth:120 }}>
              <div className="pl-mini-timeline">{p.segs.map((s,i)=><span key={i} style={{ width:s[1]+"%", background:s[0] }}/>)}</div>
              <div style={{ fontSize:11, color:"var(--slate-400)", marginTop:5 }}>{p.slides} slides · {p.dur} loop</div>
            </div>
            <div style={{ display:"flex", alignItems:"center", gap:18, flex:"none" }}>
              <MiniStat label="Screens" val={p.screens}/>
              <div style={{ width:88, textAlign:"center" }}>
                {p.status==="published" ? <span className="badge badge-green"><span className="dot"/>{p.version} live</span> : <span className="badge badge-amber"><span className="dot"/>Draft</span>}
              </div>
              <span style={{ fontSize:12, color:"var(--slate-400)", width:70, textAlign:"right" }}>{p.updated}</span>
              <button className="icon-btn-sm" onClick={e=>e.stopPropagation()}><Icon name="dots" size={16}/></button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
window.AdsList = AdsList; window.PlaylistsList = PlaylistsList;
