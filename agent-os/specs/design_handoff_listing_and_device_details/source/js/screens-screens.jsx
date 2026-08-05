/* Screens management — inventory, filters, bulk actions */
function Screens({ go }) {
  const [detail, setDetail] = useState(null);
  const [view, setView] = useState("grid");
  const [filter, setFilter] = useState("all");
  const [sel, setSel] = useState([]);
  const [swap, setSwap] = useState(null);
  const PLAYLISTS = ["Bushwick · Featured", "Open Houses · Wknd", "Brand Loop", "WMSBG · Rentals", "HY · Luxury Showcase"];
  const list = SCREENS.filter(s => filter==="all" ? true : filter==="live" ? s.status==="live" : filter==="offline" ? s.status!=="live" : true);
  const toggle = id => setSel(p => p.includes(id) ? p.filter(x=>x!==id) : [...p, id]);
  const allOn = list.length>0 && list.every(s=>sel.includes(s.id));

  return (
    <div className="page">
      <Note>
        <b>Screens = the physical displays.</b> Non-technical managers can't picture a screen from a row of text, so the default <b>grid shows a live thumbnail of what's actually playing</b> — the fastest way to spot a frozen or wrong-content screen. A table view is one click away for power users who want to scan heartbeats and bulk-reassign playlists.
      </Note>

      <div className="ph-head">
        <div><h2>Screens</h2><p>{SCREENS.length} screens · {SCREENS.filter(s=>s.status==="live").length} live · 1 offline · 1 unassigned</p></div>
        <div className="ph-actions">
          <Segmented options={[{value:"grid",label:"Grid",icon:"grid"},{value:"table",label:"Table",icon:"list"}]} value={view} onChange={setView}/>
          <button className="btn btn-primary"><Icon name="plus" size={15}/>Add screen</button>
        </div>
      </div>

      <div className="toolbar">
        <div className="search"><Icon name="search" size={15}/><input className="input" placeholder="Search screens…"/></div>
        <div style={{ display:"flex", gap:8 }}>
          {[["all","All"],["live","Live"],["offline","Issues"]].map(([v,l])=>(
            <button key={v} className={"chip"+(filter===v?" on":"")} onClick={()=>setFilter(v)}>{l}</button>
          ))}
        </div>
        <button className="chip"><Icon name="filter" size={14}/>Site</button>
        <button className="chip"><Icon name="filter" size={14}/>Orientation</button>
      </div>

      {view==="grid" ? (
        <div className="card-grid" style={{ gridTemplateColumns:"repeat(4,1fr)" }}>
          {list.map(s=>(
            <div className="scr-tile" key={s.id} style={{ outline: sel.includes(s.id)?"2px solid var(--blue)":"none", zIndex: swap===s.id?20:"auto" }}>
              <div className="scr-prev" style={{ cursor:"pointer" }} onClick={()=>setDetail(s)}>
                <ScreenContent screen={s}/>
                <span className="live-tag"><Badge status={s.status}/></span>
                <button className={"row-check"+(sel.includes(s.id)?" on":"")} style={{ position:"absolute", top:9, left:9, zIndex:2 }} onClick={()=>toggle(s.id)}>
                  {sel.includes(s.id) && <Icon name="check" size={12} sw={3}/>}</button>
              </div>
              <div className="scr-meta">
                <div style={{ display:"flex", alignItems:"center", justifyContent:"space-between" }}>
                  <span className="cell-strong scr-link" style={{ fontSize:14 }} onClick={()=>setDetail(s)}>{s.name}</span>
                  <span className="badge badge-gray" style={{ fontSize:10.5 }}>{s.orient}</span>
                </div>
                <div style={{ fontSize:12, color:"var(--slate-400)", marginTop:2 }}>{s.site}</div>
                <div style={{ display:"flex", alignItems:"center", gap:6, marginTop:10, fontSize:12, color:"var(--slate-500)" }}>
                  <Icon name="playlists" size={13}/><span style={{flex:1, overflow:"hidden", textOverflow:"ellipsis", whiteSpace:"nowrap"}}>{s.playlist}</span>
                </div>
                <div style={{ display:"flex", alignItems:"center", gap:6, marginTop:6, fontSize:11.5, color:"var(--slate-400)" }}>
                  <Icon name={s.status==="live"?"wifi":"wifiOff"} size={13} style={{color: s.status==="live"?"var(--green)":"var(--red)"}}/>
                  {s.status==="live"?"Heartbeat "+s.heartbeat : s.status==="offline"?"Offline · "+s.heartbeat : "No player assigned"}
                </div>
                <div style={{ position:"relative", marginTop:11 }}>
                  <button className="btn btn-secondary btn-sm" style={{ width:"100%" }} onClick={()=>setSwap(swap===s.id?null:s.id)}>
                    <Icon name="playlists" size={14}/>Change content<Icon name="chevronD" size={12} style={{ marginLeft:"auto", opacity:.6 }}/>
                  </button>
                  {swap===s.id && (
                    <div className="swap-pop" onMouseLeave={()=>setSwap(null)}>
                      <div className="swap-t">Play on this screen</div>
                      {PLAYLISTS.map(pl=>(
                        <button key={pl} className={"swap-item"+(pl===s.playlist?" on":"")} onClick={()=>setSwap(null)}>
                          <Icon name="playlists" size={14}/>{pl}{pl===s.playlist && <Icon name="check" size={14} sw={2.4} style={{marginLeft:"auto",color:"var(--blue)"}}/>}
                        </button>
                      ))}
                    </div>
                  )}
                </div>
              </div>
            </div>
          ))}
        </div>
      ) : (
        <div className="tbl-wrap">
          <table className="tbl">
            <thead><tr>
              <th style={{ width:44, paddingLeft:18 }}><button className={"row-check"+(allOn?" on":"")} onClick={()=>setSel(allOn?[]:list.map(s=>s.id))}>{allOn&&<Icon name="check" size={12} sw={3}/>}</button></th>
              <th>Screen</th><th>Site</th><th>Player</th><th>Playlist</th><th>Status</th><th>Heartbeat</th><th></th>
            </tr></thead>
            <tbody>
              {list.map(s=>(
                <tr key={s.id}>
                  <td style={{ paddingLeft:18 }}><button className={"row-check"+(sel.includes(s.id)?" on":"")} onClick={()=>toggle(s.id)}>{sel.includes(s.id)&&<Icon name="check" size={12} sw={3}/>}</button></td>
                  <td><div style={{ display:"flex", alignItems:"center", gap:11, cursor:"pointer" }} onClick={()=>setDetail(s)}>
                    <div style={{ width:48, height:30, borderRadius:5, overflow:"hidden", flex:"none", position:"relative", background:"var(--ink-900)" }}><ScreenContent screen={s} mini/></div>
                    <span className="cell-strong scr-link">{s.name}</span></div></td>
                  <td className="muted">{s.site}</td>
                  <td className="muted mono" style={{ fontSize:12.5 }}>{s.player}</td>
                  <td className="muted">{s.playlist}</td>
                  <td><Badge status={s.status}/></td>
                  <td className="muted mono" style={{ fontSize:12.5 }}>{s.heartbeat}</td>
                  <td><button className="icon-btn-sm"><Icon name="dots" size={16}/></button></td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {sel.length>0 && (
        <div className="bulkbar">
          <span className="b-count">{sel.length} selected</span>
          <span className="b-sep"/>
          <button className="btn btn-ghost btn-sm"><Icon name="playlists" size={15}/>Assign playlist</button>
          <button className="btn btn-ghost btn-sm"><Icon name="refresh" size={15}/>Restart</button>
          <button className="btn btn-ghost btn-sm"><Icon name="upload" size={15}/>Publish</button>
          <span className="b-sep"/>
          <button className="btn btn-ghost btn-sm" onClick={()=>setSel([])}>Clear</button>
        </div>
      )}

      {detail && <ScreenDetail screen={detail} onClose={()=>setDetail(null)} go={go}/>}
    </div>
  );
}

/* tiny live render of what a screen is showing */
function ScreenContent({ screen, mini }) {
  if (screen.status === "idle") return <div style={{position:"absolute",inset:0,display:"grid",placeItems:"center",color:"#3b414e",fontSize:mini?8:11}}>—</div>;
  if (screen.status === "offline") return <div style={{position:"absolute",inset:0,display:"grid",placeItems:"center",background:"#0b0d12"}}><Icon name="wifiOff" size={mini?12:22} style={{color:"#3b414e"}}/></div>;
  const variants = {
    "Bushwick · Featured": <HeroMini price="$1.25M" addr="124 Maple Ave" mini={mini}/>,
    "Open Houses · Wknd": <OpenMini mini={mini}/>,
    "Brand Loop": <BrandMini mini={mini}/>,
    "WMSBG · Rentals": <HeroMini price="$4,200/mo" addr="88 Bedford Ave" tone="#0fb5a6" mini={mini}/>,
    "HY · Luxury Showcase": <HeroMini price="$8.95M" addr="20 Hudson Yards" tone="#7c5cff" mini={mini}/>,
  };
  return variants[screen.playlist] || <HeroMini price="$1.25M" addr="Listing" mini={mini}/>;
}
function HeroMini({ price, addr, tone="#2f6bff", mini }) {
  return <div style={{ position:"absolute", inset:0, background:`linear-gradient(135deg, #14171f, ${tone}33)`, padding: mini?4:"14px", display:"flex", flexDirection:"column", justifyContent:"flex-end", color:"#fff" }}>
    <div style={{ position:"absolute", top:mini?3:10, left:mini?3:12, fontSize:mini?6:10, color:tone==="#2f6bff"?"#7aa2ff":"#fff", fontWeight:700, opacity:.9 }}>{mini?"":"FOR SALE"}</div>
    <div style={{ fontSize:mini?9:22, fontWeight:700, letterSpacing:"-.02em" }}>{price}</div>
    {!mini && <div style={{ fontSize:11, opacity:.85 }}>{addr}</div>}
    {!mini && <div style={{ position:"absolute", right:12, bottom:12, width:28, height:28, background:"#fff", borderRadius:4 }}/>}
  </div>;
}
function OpenMini({ mini }) {
  return <div style={{ position:"absolute", inset:0, background:"linear-gradient(135deg,#1f54e0,#0fb5a6)", display:"grid", placeItems:"center", color:"#fff", textAlign:"center" }}>
    <div><div style={{ fontSize:mini?7:11, fontWeight:700, opacity:.85 }}>{mini?"OPEN":"OPEN HOUSE"}</div><div style={{ fontSize:mini?9:18, fontWeight:700 }}>{mini?"SAT":"Sat 2–4PM"}</div></div>
  </div>;
}
function BrandMini({ mini }) {
  return <div style={{ position:"absolute", inset:0, background:"#0b0d12", display:"grid", placeItems:"center", color:"#fff" }}>
    <div style={{ textAlign:"center" }}><div style={{ width:mini?12:26, height:mini?12:26, borderRadius:6, background:"linear-gradient(135deg,#2f6bff,#0fb5a6)", margin:"0 auto 4px" }}/><div style={{ fontSize:mini?7:13, fontWeight:700 }}>Vantage</div></div>
  </div>;
}
window.Screens = Screens;
Object.assign(window, { ScreenContent, HeroMini, OpenMini, BrandMini });
