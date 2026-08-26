/* Listings + Campaigns */
function Listings({ go, openEditor }) {
  const [view, setView] = useState("gallery");
  const [area, setArea] = useState("all");
  const list = LISTINGS.filter(l => area==="all" || l.area===area);
  const areas = ["all", ...new Set(LISTINGS.map(l=>l.area))];

  return (
    <div className="page">
      <Note>
        <b>Listings = the property data ads are built from.</b> This is a media library first, a database second — so the default is an <b>image-heavy gallery</b> that mirrors how the content will appear on screen. “Use in ad” is the primary action on every card, making the path from inventory → signage one click.
      </Note>
      <div className="ph-head">
        <div><h2>Listings</h2><p>{LISTINGS.length} properties · synced from MLS 6m ago</p></div>
        <div className="ph-actions">
          <Segmented options={[{value:"gallery",label:"Gallery",icon:"grid"},{value:"table",label:"Table",icon:"list"}]} value={view} onChange={setView}/>
          <button className="btn btn-secondary"><Icon name="refresh" size={15}/>Sync MLS</button>
          <button className="btn btn-primary" onClick={()=>openEditor && openEditor()}><Icon name="plus" size={15}/>New listing</button>
        </div>
      </div>
      <div className="toolbar">
        <div className="search"><Icon name="search" size={15}/><input className="input" placeholder="Search by address…"/></div>
        <div style={{ display:"flex", gap:8, flexWrap:"wrap" }}>
          {areas.map(a=>(<button key={a} className={"chip"+(area===a?" on":"")} onClick={()=>setArea(a)}>{a==="all"?"All areas":a}</button>))}
        </div>
      </div>

      {view==="gallery" ? (
        <div className="card-grid" style={{ gridTemplateColumns:"repeat(4,1fr)" }}>
          {list.map(l=>(
            <div className="listing-card" key={l.id} onClick={()=>go("listing-"+l.id)}>
              <div className="lc-media ph" data-label="property photo" style={{ background:l.tone+"22" }}>
                <div style={{ position:"absolute", inset:0, background:`linear-gradient(160deg, ${l.tone}33, transparent 70%)` }}/>
                <span className="lc-status"><Badge status={l.status}/></span>
                <span className="lc-fav"><Icon name="ads" size={15}/></span>
              </div>
              <div className="lc-body">
                <div className="lc-price tabular">{fmtPrice(l.price)}</div>
                <div className="lc-addr">{l.addr}</div>
                <div className="lc-area">{l.area} · {l.type}</div>
                <div className="lc-specs">
                  <span><Icon name="bed" size={14}/>{l.beds} bd</span>
                  <span><Icon name="bath" size={14}/>{l.baths} ba</span>
                  <span><Icon name="sqft" size={14}/>{l.sqft.toLocaleString()}</span>
                </div>
                <button className="btn btn-secondary btn-sm" style={{ width:"100%", marginTop:12 }} onClick={(e)=>{e.stopPropagation(); go("ad-builder");}}><Icon name="ads" size={14}/>Use in ad</button>
              </div>
            </div>
          ))}
        </div>
      ) : (
        <div className="tbl-wrap">
          <table className="tbl">
            <thead><tr><th style={{paddingLeft:18}}>Property</th><th>Area</th><th>Type</th><th>Price</th><th>Beds</th><th>Baths</th><th>Sq ft</th><th>Status</th><th></th></tr></thead>
            <tbody>{list.map(l=>(
              <tr key={l.id} style={{ cursor:"pointer" }} onClick={()=>go("listing-"+l.id)}>
                <td style={{paddingLeft:18}}><div style={{display:"flex",alignItems:"center",gap:11}}>
                  <div className="ph" data-label="" style={{ width:46, height:34, borderRadius:6, flex:"none", background:l.tone+"22" }}/>
                  <span className="cell-strong">{l.addr}</span></div></td>
                <td className="muted">{l.area}</td><td className="muted">{l.type}</td>
                <td className="cell-strong mono">{fmtPrice(l.price)}</td>
                <td className="muted mono">{l.beds}</td><td className="muted mono">{l.baths}</td><td className="muted mono">{l.sqft.toLocaleString()}</td>
                <td><Badge status={l.status}/></td>
                <td><button className="icon-btn-sm" onClick={(e)=>e.stopPropagation()}><Icon name="dots" size={16}/></button></td>
              </tr>
            ))}</tbody>
          </table>
        </div>
      )}
    </div>
  );
}

function Campaigns({ go }) {
  return (
    <div className="page">
      <Note>
        <b>Campaigns group ads toward a goal</b> (a season of open houses, a recruiting push) and schedule them across sites. Marketing managers live in outcomes, so each campaign leads with <b>performance and schedule</b>, not its contents. A Gantt-style timeline makes overlaps and gaps obvious at a glance.
      </Note>
      <div className="ph-head">
        <div><h2>Campaigns</h2><p>{CAMPAIGNS.length} campaigns · 3 live · 1 scheduled</p></div>
        <div className="ph-actions"><button className="btn btn-primary"><Icon name="plus" size={15}/>New campaign</button></div>
      </div>

      {/* timeline */}
      <div className="card" style={{ marginBottom:18, padding:"18px 20px" }}>
        <div style={{ display:"flex", justifyContent:"space-between", marginBottom:14 }}>
          <h3 style={{ fontSize:15, fontWeight:650, margin:0 }}>Schedule</h3>
          <div style={{ fontSize:12, color:"var(--slate-400)" }}>Feb — Aug 2026</div>
        </div>
        <div style={{ display:"flex", flexDirection:"column", gap:9 }}>
          {CAMPAIGNS.map(c=>{
            const spans = { c1:[33,72], c2:[18,82], c3:[66,100], c4:[8,100], c5:[0,100] };
            const [a,b] = spans[c.id];
            return (
              <div key={c.id} style={{ display:"flex", alignItems:"center", gap:14 }}>
                <div style={{ width:170, flex:"none", fontSize:13, fontWeight:600, overflow:"hidden", textOverflow:"ellipsis", whiteSpace:"nowrap" }}>{c.name}</div>
                <div style={{ flex:1, position:"relative", height:26, background:"var(--surface-3)", borderRadius:7 }}>
                  <div style={{ position:"absolute", left:a+"%", width:(b-a)+"%", top:0, bottom:0, borderRadius:7, background:c.status==="paused"?"var(--slate-300)":c.color, opacity:c.status==="scheduled"?.45:1, display:"flex", alignItems:"center", paddingLeft:10, color:"#fff", fontSize:11, fontWeight:600 }}>{c.start}</div>
                </div>
                <div style={{ width:70, flex:"none", textAlign:"right" }}><Badge status={c.status}/></div>
              </div>
            );
          })}
        </div>
      </div>

      <div className="card-grid" style={{ gridTemplateColumns:"repeat(3,1fr)" }}>
        {CAMPAIGNS.map(c=>(
          <div className="card card-pad" key={c.id} style={{ cursor:"pointer" }}>
            <div style={{ display:"flex", alignItems:"center", justifyContent:"space-between", marginBottom:12 }}>
              <span style={{ width:34, height:34, borderRadius:9, background:c.color+"18", color:c.color, display:"grid", placeItems:"center" }}><Icon name="campaigns" size={17}/></span>
              <Badge status={c.status}/>
            </div>
            <h3 style={{ fontSize:16, fontWeight:650, margin:"0 0 3px", letterSpacing:"-.01em" }}>{c.name}</h3>
            <div style={{ fontSize:12.5, color:"var(--slate-400)" }}>{c.ads} ads · {c.sites} sites · {c.start}–{c.end}</div>
            <div style={{ display:"flex", gap:18, marginTop:14, paddingTop:14, borderTop:"1px solid var(--line-2)" }}>
              <MiniStat label="QR scans" val={c.scans.toLocaleString()}/>
              <MiniStat label="Ads" val={c.ads}/>
              <MiniStat label="Sites" val={c.sites}/>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
window.Listings = Listings; window.Campaigns = Campaigns;
